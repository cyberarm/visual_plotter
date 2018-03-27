require_relative "machine/pen"
require_relative "machine/bed"
require_relative "machine/canvas "
require_relative "machine/image_processor"
require_relative "machine/compiler"

class Machine
  attr_reader :pen, :bed, :compiler, :canvas, :thread_safe_queue, :plotter_threshold, :invert_plotter, :plotter_forward, :plotter_steps
  attr_accessor :plotter_run
  def initialize(window:, width: 11*40, height: 8.5*40)
    @thread_safe_queue = []
    @window = window
    @width, @height = width, height

    @bed = Bed.new(width: width, height: height)
    @pen = Pen.new(machine: self, x: @bed.x, y: @bed.y)
    @compiler = Compiler.new(machine: self)
    @pen.plot = false
    new_canvas
    @bed_padding = 100
    @invert_plotter = false
    @plotter_threshold = 90
    @plotter_run = false
    @plotter_forward = true
    @plotter_steps = @bed.width
    @rcode_events = nil
    @rcode_index  = 0

    @status_text = Text.new(text: "Status: Waiting for file...", x: @bed.x, y: 30, size: 24)
    @x_pos = Text.new(text: "X: ?", x: @bed.x+@bed.width/2, y: @bed.y-30)
    @y_pos = Text.new(text: "Y: ?", x: @bed.x+@bed.width+10, y: @bed.y+@bed.height/2)
    @pen_mode = Text.new(text: "Plot: false", x: @bed.x+@bed.width/2, y: @bed.y+@bed.height+10)
    @target = Text.new(text: "Target", x: @bed.x+@bed.width+@bed_padding+@bed.width/2, y: @bed.y-30)
    @plotter_state = Text.new(text: "Plotter inverted: #{@invert_plotter}", x: @bed.x, y: @bed.y-50)

    @fps = Text.new(text: "FPS: 0", x: @window.width-75, y: 10)
  end

  def draw
    @bed.draw
    @canvas.draw
    draw_rails
    @pen.draw

    @status_text.draw
    @x_pos.draw
    @y_pos.draw
    @pen_mode.draw
    @target.draw
    @fps.draw
    @plotter_state.draw

    # @target_image.draw(0,0,100) if @target_image
    Gosu.draw_rect(@bed.x+@bed.width+@bed_padding, @bed.y, @bed.width, @bed.height, @bed.color)
    @target_image.draw(@bed.x+@bed.width+@bed_padding, @bed.y, 10) if @target_image
  end

  def draw_rails
    # X Axis
    Gosu.draw_rect(@pen.x-1, @bed.y, 3, @bed.height, Gosu::Color::CYAN, 100)
    # Y Axis
    Gosu.draw_rect(@bed.x, @pen.y-1, @bed.width, 3, Gosu::Color::CYAN, 100)
  end

  def update
    @x_pos.text = "X: #{(@pen.x-@bed.x).round(2)}"
    @y_pos.text = "Y: #{(@pen.y-@bed.y).round(2)}"
    @pen_mode.text = "Plot: #{@pen.plot}"
    @fps.text = "FPS: #{Gosu.fps}"
    @plotter_state.text = "Plotter inverted: #{@invert_plotter}, threshold: #{@plotter_threshold}, run: #{@plotter_run}, forward: #{@plotter_forward}, steps: #{@plotter_steps} #{@rcode_events ? rcode_stats: ''}"

    @thread_safe_queue.pop.call if @thread_safe_queue.size > 0

    if @chunky_image && @plotter_run
      @plotter_steps.times { run_plotter if @chunky_image }
      # @chunky_image.width.times { run_plotter if @chunky_image }
      @canvas.refresh
    elsif @rcode_events.is_a?(Array) && @plotter_run
      @plotter_steps.times { rcode_plot }
      @canvas.refresh
    end
  end

  def plot
    status(:okay, "Plotting...")
    color = ChunkyPNG::Color.r(@chunky_image[@pen.x-@bed.x, @pen.y-@bed.y])
    if @invert_plotter
      @pen.plot = (color > @plotter_threshold) ? true : false
    else
      @pen.plot = (color < @plotter_threshold) ? true : false
    end
    @pen.update

    if @compiler.events.size == 0
      @compiler.add_event(type: "pen_up")
      @compiler.add_event(type: "home")
    else

      if @pen.plot
        @compiler.add_event(type: "pen_down")
      else
        @compiler.add_event(type: "pen_up")
      end
    end

    if @plotter_forward
      if (@pen.x-@bed.x)+1 < @chunky_image.width
        @pen.x+=1
      else
        @compiler.add_event(type: "move", x: @pen.x-@bed.x, y: @pen.y-@bed.y) if @pen.plot
        @plotter_forward = false
      end
    else
      if (@pen.x-@bed.x)-1 > 0
        @pen.x-=1
      else
        @plotter_forward = true
        @pen.x = @bed.x
        @compiler.add_event(type: "move", x: @pen.x-@bed.x, y: @pen.y-@bed.y) if @pen.plot
        @pen.y+=1
      end
    end
  end

  def run_plotter
    if @chunky_image.get_pixel(@pen.x-@bed.x, @pen.y-@bed.y) &&
      (@pen.x-@bed.x < @chunky_image.width && @pen.x-@bed.x < @bed.width)
      plot

    elsif @pen.y-@bed.y > @chunky_image.height-1
      @plotter_run = false
      status(:okay, "Plotting complete.")
    else
      @pen.y+=1
    end
  end

  def save(name = "complete.png")
    @canvas.save("complete.png") if !@plotter_run
    status(:okay, "Saved canvas.") if !@plotter_run
  end

  def replot
    new_canvas
    @pen.x = @bed.x
    @pen.y = @bed.y
    @plotter_run = true
    @rcode_index = 0
  end

  def plot_from_rcode(file)
    @rcode_events = Compiler.decompile(file)
    replot
    status(:okay, "Plotting from #{file.gsub("\\", "/").split("/").last}...")
  end

  def rcode_stats
    ", rcode events: #{@rcode_index}/#{@rcode_events.size-1}"
  end

  def rcode_plot
    instruction = @rcode_events[@rcode_index]
    @rcode_index+=1 if @rcode_index < @rcode_events.size
    if @rcode_index >= @rcode_events.size-1
      @plotter_run = false
      status(:okay, "Plotting from rcode complete.")
      return
    end
    case instruction.type.downcase
    when "home"
      @pen.x = @bed.x
      @pen.y = @bed.y
    when "pen_up"
      @pen.plot = false
    when "pen_down"
      @pen.plot = true
    when "move"
      if @pen.plot
        @pen.y = @bed.y+instruction.y # bad idea, fixme?
        if @bed.x+instruction.x < @pen.x
          @pen.x-(@bed.x+instruction.x).times {@pen.x-=1 if @pen.x-1 > @bed.x; @pen.paint}
        else
          @pen.x-(@bed.x+instruction.x).times {@pen.x+=1 if @pen.x+1 < @bed.x+@bed.width; @pen.paint}
        end
      else
        @pen.x = @bed.x+instruction.x
        @pen.y = @bed.y+instruction.y
      end
    end
  end

  # invert plotter color choices
  def invert_plotter
    @invert_plotter = !@invert_plotter
  end

  def plotter_threshold=int
    int = int.clamp(1, 255)
    @plotter_threshold = int
  end

  def plotter_steps=int
    int = int.clamp(1, @bed.width)
    @plotter_steps = int
  end

  def status(level, string)
    case level
    when :okay
      @status_text.color = Gosu::Color::WHITE
    when :warn
      @status_text.color = Gosu::Color::YELLOW
    when :error
      @status_text.color = Gosu::Color::RED
    end
    @status_text.text = "Status: #{string}"
  end

  def new_canvas
    @canvas = Canvas.new(machine: self, x: @bed.x, y: @bed.y, width: @bed.width, height: @bed.height)
  end

  def image_ready(image)
    @compiler.reset
    @chunky_image = image
    # @chunky_image.save("temp.png")
    @target_image = Gosu::Image.new(Magick::Image.new(image))
    status(:okay, "Image processed.")
  end

  def process_file(file)
    name= file.gsub("\\", "/").split("/").last
    ext = name.split(".").last
    if ext.is_a?(Array)
      status(:error, "File #{name} is of an unknown type (.#{ext}), only the common types are supported.")
      return
    end

    if ext.downcase == "rcode"
      @chunky_image = nil
      @target_image = nil
      @canvas.clear
      @canvas = nil

      @rcode_events = nil
      @rcode_index = 0
      new_canvas
      status(:okay, "Parsing #{name}...")
      plot_from_rcode(file)
      return
    end

    status(:okay, "Processing image...")

    begin
      @chunky_image = nil
      @target_image = nil
      @canvas.clear
      @canvas = nil

      # HALT THE WORLD AND FREE THE MEMORY?
      GC.start(full_mark: true, immediate_sweep: true)

      new_canvas
      @pen.x, @pen.y = @bed.x, @bed.y
      ImageProcessor.new(file, self)
    rescue => e
      puts e, e.class
      status(:error, "Unable to open #{name}, is it an image?")
      return
    end
  end
end
