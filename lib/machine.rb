require_relative "machine/pen"
require_relative "machine/bed"
require_relative "machine/canvas "
require_relative "machine/image_processor"
require_relative "machine/compiler"

class Machine
  attr_reader :pen, :bed, :compiler, :canvas, :thread_safe_queue
  attr_reader :plotter_threshold, :invert_plotter, :plotter_forward, :plotter_steps

  attr_reader :rcode_events, :chunky_image

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

    @status_text = Text.new(text: "", x: @bed.x, y: 30, size: 24)
    status(:okay, "Status: Waiting for file...")
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
    Gosu.draw_rect(@bed.x, @pen.y-1, @bed.width, 3, Gosu::Color.rgba(200, 0, 0, 200), 100)
    # Y Axis
    Gosu.draw_rect(@pen.x-1, @bed.y, 3, @bed.height, Gosu::Color.rgba(0, 200, 0, 200), 100)
  end

  def update
    @x_pos.text = "X: #{(pen_x).round(2)}"
    @y_pos.text = "Y: #{(pen_y).round(2)}"
    @pen_mode.text = "Plot: #{@pen.plot}"
    @fps.text = "FPS: #{Gosu.fps}"
    @plotter_state.text = "Plotter inverted: #{@invert_plotter}, threshold: #{@plotter_threshold}, run: #{@plotter_run}, forward: #{@plotter_forward}, steps: #{@plotter_steps} #{@rcode_events ? rcode_stats: ''}"

    @thread_safe_queue.pop.call if @thread_safe_queue.size > 0

    if @chunky_image && @plotter_run
      @plotter_steps.times { run_plotter if @plotter_run }
      @canvas.refresh
    elsif @rcode_events.is_a?(Array) && @plotter_run
      @plotter_steps.times { rcode_plot if @plotter_run }
      @canvas.refresh
    end
  end

  def button_up(id)
    case id
    when Gosu::KbI
      invert_plotter
    when Gosu::KbR
      @plotter_run = !@plotter_run
    when Gosu::KbS
      save if !@plotter_run
    when Gosu::KbF5
      replot
    when Gosu::KbHome
      if @window.button_down?(Gosu::KbLeftControl || Gosu::KbRightControl)
        @plotter_steps = (@bed.width*@bed.height).to_i
      else
        @plotter_steps = @bed.width
      end
    when Gosu::KbEnd
      @plotter_steps = 1
    when Gosu::KbEqual
      @plotter_steps+=1
    when Gosu::KbMinus
      @plotter_steps-=1
    when Gosu::MsWheelUp
      @plotter_threshold+=1
    when Gosu::MsWheelDown
      @plotter_threshold-=1
    end
  end

  def plot
    status(:busy, "Plotting...")
    color = ChunkyPNG::Color.r(@chunky_image[pen_x, pen_y])

    if @compiler.events.size == 0
      @compiler.add_event(type: "pen_up")
      @compiler.add_event(type: "home")
    else
      if @invert_plotter
        @pen.plot = (color >= @plotter_threshold) ? true : false
      else
        @pen.plot = (color <= @plotter_threshold) ? true : false
      end

      if @pen.plot
        @compiler.add_event(type: "pen_down")
      else
        @compiler.add_event(type: "pen_up")
      end
    end

    @pen.update
    # NO PLOTTING OR EVENTS AFTER THIS LINE

    if @plotter_forward
      if (pen_x)+1 < @chunky_image.width
        @pen.x+=1
      else
        @plotter_forward = false
        @compiler.add_event(type: "move", x: pen_x-1, y: pen_y) if @pen.plot
        @pen.y+=1
        @compiler.add_event(type: "move", x: pen_x-1, y: pen_y) if @pen.plot
      end
    else
      if (pen_x)-1 > 0
        @pen.x-=1
      else
        @plotter_forward = true
        @pen.x = @bed.x
        @compiler.add_event(type: "move", x: pen_x+1, y: pen_y) if @pen.plot
        @pen.y+=1
        @compiler.add_event(type: "move", x: pen_x+1, y: pen_y) if @pen.plot
      end
    end
  end

  def run_plotter
    if  pen_y >= @chunky_image.height-1
      @plotter_run = false
      status(:okay, "Plotting complete.")
    elsif @chunky_image.get_pixel(pen_x, pen_y) &&
      (pen_x < @chunky_image.width && pen_x < @bed.width)
      plot
    else
      @pen.y+=1
    end
  end

  def save(name = "complete-#{Time.now.strftime('%Y-%m-%d-%s')}")
    @canvas.save("data/#{name}.png") if !@plotter_run
    status(:okay, "Saved canvas.") if !@plotter_run
  end

  def replot
    new_canvas
    @pen.x = @bed.x
    @pen.y = @bed.y
    @plotter_run = true
    @rcode_index = 0
    @compiler.events.clear
  end

  def plot_from_rcode(file)
    @rcode_events = Compiler.decompile(file)
    @rcode_file = file
    status(:okay, "Loaded #{get_filename(file)}.")
  end

  def rcode_stats
    ", rcode events: #{@rcode_index}/#{@rcode_events.size-1}"
  end

  def rcode_plot
    instruction = @rcode_events[@rcode_index]
    @rcode_index+=1 if @rcode_index < @rcode_events.size-1
    if @rcode_index >= @rcode_events.size-1
      @plotter_run = false
      status(:okay, "Plotted rcode.")
      return
    end
    status(:busy, "Plotting from #{get_filename(@rcode_file)}...")
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
        until(@pen.y == @bed.y+instruction.y)
          break unless @plotter_run

          @pen.y+=1
          @pen.paint
        end

        x_target = @bed.x+instruction.x
        until(@pen.x == x_target)
          break unless @plotter_run

          if x_target < @pen.x
            @pen.x-=1
            @pen.paint
          elsif x_target > @pen.x
            @pen.x+=1
            @pen.paint
          else
            raise "This should be impossible."
          end
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
      @status_text.color = Gosu::Color.rgb(25, 200, 25)
    when :busy
      @status_text.color = Gosu::Color.rgb(255, 127, 0)
    when :warn
      @status_text.color = Gosu::Color::YELLOW
    when :error
      @status_text.color = Gosu::Color::RED
    end
    @status_text.text = "Status: #{string}"
  end

  def pen_x
    @pen.x-@bed.x
  end

  def pen_y
    @pen.y-@bed.y
  end

  def new_canvas
    @canvas = Canvas.new(machine: self, x: @bed.x, y: @bed.y, width: @bed.width, height: @bed.height)
  end

  def image_ready(image, file)
    @compiler.reset
    @chunky_image = image
    # @chunky_image.save("temp.png")
    @target_image = Gosu::Image.new(Magick::Image.new(image))
    status(:okay, "Image #{get_filename(file)} ready.")
  end

  def get_filename(file)
    file.gsub("\\", "/").split("/").last
  end

  def process_file(file)
    name= get_filename(file)
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

      @rcode_events = nil
      @rcode_index = 0

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
