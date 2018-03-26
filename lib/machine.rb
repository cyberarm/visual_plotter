require_relative "machine/pen"
require_relative "machine/bed"
require_relative "machine/canvas "
require_relative "machine/image_processor"
require_relative "machine/compiler"

class Machine
  attr_reader :pen, :bed, :canvas, :thread_safe_queue, :plotter_threshold, :invert_plotter, :plotter_forward, :plotter_steps
  attr_accessor :plotter_run
  def initialize(window:, width: 11*40, height: 8.5*40)
    @thread_safe_queue = []
    @window = window
    @width, @height = width, height

    @bed = Bed.new(width: width, height: height)
    @pen = Pen.new(machine: self, x: @bed.x, y: @bed.y)
    @pen.plot = false
    @canvas = Canvas.new(machine: self, x: @bed.x, y: @bed.y, width: @bed.width, height: @bed.height)
    @bed_padding = 100
    @invert_plotter = false
    @plotter_threshold = 90
    @plotter_run = false
    @plotter_forward = true
    @plotter_steps = @bed.width

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
    @plotter_state.text = "Plotter inverted: #{@invert_plotter}, threshold: #{@plotter_threshold}, run: #{@plotter_run}, forward: #{@plotter_forward}, steps: #{@plotter_steps}"

    @thread_safe_queue.pop.call if @thread_safe_queue.size > 0

    if @chunky_image && @plotter_run
      @plotter_steps.times { run_plotter if @chunky_image }
      # @chunky_image.width.times { run_plotter if @chunky_image }
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
    if @plotter_forward
      if (@pen.x-@bed.x)+1 < @chunky_image.width
        @pen.x+=1
      else
        @plotter_forward = false
      end
    else
      if (@pen.x-@bed.x)-1 > 0
        @pen.x-=1
      else
        @plotter_forward = true
        @pen.x = @bed.x
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
    @canvas.save("complete.png")
  end

  def replot
    @canvas = Canvas.new(machine: self, x: @bed.x, y: @bed.y, width: @bed.width, height: @bed.height)
    @pen.x = @bed.x
    @pen.y = @bed.y
    @plotter_run = true
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

  def image_ready(image)
    @chunky_image = image
    # @chunky_image.save("temp.png")
    @plotter_run = true
    @target_image = Gosu::Image.new(Magick::Image.new(image))
    # @target_image = Gosu::Image.new("temp.png")
    # puts "IMAGE: #{@target_image.width}x#{@target_image.height}"
    # @target_image.save("post_test.png")
    status(:okay, "Image processed.")
  end

  def process_file(file)
    name= file.gsub("\\", "/").split("/").last
    ext = name.split(".").last
    if ext.is_a?(Array)# || ext.downcase != "png"
      status(:error, "File #{name} is of an unknown type (.#{ext}), only the common types are supported.")
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

      @canvas = Canvas.new(machine: self, x: @bed.x, y: @bed.y, width: @bed.width, height: @bed.height)
      @pen.x, @pen.y = @bed.x, @bed.y
      ImageProcessor.new(file, self)
    rescue => e
      puts e, e.class
      status(:error, "Unable to open #{name}, is it an image?")
      return
    end
  end
end
