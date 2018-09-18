require_relative "machine/pen"
require_relative "machine/bed"
require_relative "machine/canvas"
require_relative "machine/end_stop"
require_relative "machine/image_processor"
require_relative "machine/plotter"
require_relative "machine/plotters/image_plotter"
require_relative "machine/plotters/rcode_plotter"
require_relative "machine/compiler"
require_relative "machine/compiler/processor"
require_relative "machine/compiler/solvers/classic"
require_relative "machine/compiler/solvers/graph_search"
require_relative "machine/compiler/solvers/generational"

class Machine
  attr_reader :pen, :bed, :compiler, :plotter, :canvas, :thread_safe_queue, :x_endstop, :y_endstop
  attr_reader :ghost_pen
  attr_reader :rcode_events, :rcode_file, :chunky_image

  def initialize(window:, width: 14*40, height: 8*40)
    @thread_safe_queue = []
    @window = window
    @width, @height = width, height

    @bed = Bed.new(width: width, height: height)
    @pen = Pen.new(machine: self, x: @bed.x, y: @bed.y)
    @ghost_pen = Pen.new(ghost: true, machine: self, x: @bed.x, y: @bed.y) # Used for network connections to show where plotter should be
    @x_endstop = EndStop.new(machine: self, x: @bed.x-15, y: @bed.y+(@bed.height/2), axis: :x)
    @y_endstop = EndStop.new(machine: self, x: @bed.x+(@bed.width/2), y: @bed.y-15, axis: :y)
    @compiler = Compiler.new(machine: self)
    @pen.plot = false
    new_canvas
    @plotter = ImagePlotter.new(machine: self)
    @bed_padding = 100
    @rcode_events = nil
    @rcode_index  = 0

    @status_text = Text.new(text: "", x: @bed.x, y: 30, size: 24)
    status(:okay, "Waiting for photo, drag 'n drop one on the window.")
    @x_pos = Text.new(text: "X: ?", x: @bed.x+@bed.width/2, y: @bed.y-30)
    @y_pos = Text.new(text: "Y: ?", x: @bed.x+@bed.width+10, y: @bed.y+@bed.height/2)
    @pen_mode = Text.new(text: "Plot: false", x: @bed.x+@bed.width/2, y: @bed.y+@bed.height+10)
    @target = Text.new(text: "Target", x: @bed.x+@bed.width+@bed_padding+@bed.width/2, y: @bed.y-30)
    @plotter_state = Text.new(text: "Plotter inverted: #{@plotter.invert}", x: @bed.x, y: @bed.y-50)

    @fps = Text.new(text: "FPS: 0", x: @window.width-75, y: 10)
  end

  def draw
    @bed.draw
    @canvas.draw
    @pen.draw
    if ARGV.join.include?("--network")
      @x_endstop.draw
      @y_endstop.draw
      @ghost_pen.draw
    end

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

  def update
    @x_pos.text = "X: #{(@plotter.pen_x).round(2)}"
    @y_pos.text = "Y: #{(@plotter.pen_y).round(2)}"
    @pen_mode.text = "Plot: #{@pen.plot}"
    @fps.text = "FPS: #{Gosu.fps}"
    @fps.x = @window.width-75
    @plotter_state.text = "Plotter inverted: #{@plotter.invert}, threshold: #{@plotter.threshold}, run: #{@plotter.run}, forward: #{@plotter.forward}, steps: #{@plotter.steps} #{!@rcode_events ? compiler_stats : ''} #{@rcode_events ? @plotter.stats : ''}"

    @thread_safe_queue.shift.call if @thread_safe_queue.size > 0

    if @chunky_image && @plotter.run
      @plotter.steps.times { @plotter.plot if @plotter.run }
      @canvas.refresh
    elsif @rcode_events.is_a?(Array) && @plotter.run
      @plotter.steps.times { @plotter.plot if @plotter.run }
      @canvas.refresh
    end
  end

  def button_up(id)
    case id
    when Gosu::KbI
      @plotter.invert = !@plotter.invert
    when Gosu::KbR
      @plotter.run = !@plotter.run
    when Gosu::KbS
      save if !@plotter.run
    when Gosu::KbF5
      replot
    when Gosu::KbHome
      if @window.button_down?(Gosu::KbLeftControl) || @window.button_down?(Gosu::KbRightControl)
        @plotter.steps = (@bed.width*@bed.height).to_i
      else
        @plotter.steps = @bed.width
      end
    when Gosu::KbEnd
      @plotter.steps = 1
    when Gosu::KbEqual
      @plotter.steps+=1
    when Gosu::KbMinus
      @plotter.steps-=1
    when Gosu::MsWheelUp
      @plotter.threshold+=1
    when Gosu::MsWheelDown
      @plotter.threshold-=1
    end
  end

  def compile
    status(:busy, "Compiling... Please wait...")
    Thread.new do
      Compiler::Processor.new(compiler: @compiler, canvas: @canvas)#, mode: :generational)
      @compiler.compile
      status(:okay, "Compiled.")
    end
  end

  def compiler_stats
    ", compiler events: #{@compiler.events.size}"
  end

  def save(name = "complete-#{Time.now.strftime('%Y-%m-%d-%s')}")
    @canvas.save("data/#{name}.png") if !@plotter.run
    status(:okay, "Saved canvas.") if !@plotter.run
  end

  def replot
    new_canvas
    @pen.x = @bed.x
    @pen.y = @bed.y
    @plotter.reset
    @plotter.run = true
    @compiler.events.clear
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

  def plot_from_rcode(file)
    @rcode_events = Compiler.decompile(file)
    @rcode_file = file
    @plotter = RCodePlotter.new(machine: self)
    status(:okay, "Loaded #{get_filename(file)}.")
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
      @plotter = ImagePlotter.new(machine: self)

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
