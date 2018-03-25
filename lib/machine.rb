require_relative "machine/pen"
require_relative "machine/bed"
require_relative "machine/image_processor"

class Machine
  attr_reader :pen, :bed
  def initialize(width: 11*40, height: 8.5*40)
    @width, @height = width, height
    @pen = Pen.new
    @bed = Bed.new(width: width, height: height)

    @status_text = Text.new(text: "Status: Waiting for file...", x: @bed.x, y: 30, size: 24)
    @x_pos = Text.new(text: "X: ?", x: @bed.x+@bed.width/2, y: @bed.y-30)
    @y_pos = Text.new(text: "Y: ?", x: @bed.x+@bed.width+10, y: @bed.y+@bed.height/2)
    @pen_mode = Text.new(text: "Plot: false", x: @bed.x+@bed.width/2, y: @bed.y+@bed.height+10)
  end

  def draw
    @bed.draw
    @pen.draw
    draw_rails

    @status_text.draw
    @x_pos.draw
    @y_pos.draw
    @pen_mode.draw
  end

  def draw_rails
    # X Axis
    Gosu.draw_rect(@pen.x, @bed.y, 2, @bed.y+@bed.height, Gosu::Color::CYAN)
    # Y Axis
    Gosu.draw_rect(@bed.x, @bed.y, 2, @bed.y+@bed.height, Gosu::Color::CYAN)
  end

  def update
    @x_pos.text = "X: #{@pen.x-@bed.x}"
    @y_pos.text = "Y: #{@pen.y-@bed.y}"
    @pen_mode.text = "Plot: #{@pen.position == :down ? 'true' : 'false'}"
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
    status(:okay, "Image processed.")
  end

  def process_file(file)
    ext = file.gsub("\\", "/").split("/").last.split(".").last
    if ext.is_a?(Array)
      status(:error, "File #{file} is of an unknown type (.#{ext}), only '.png' is supported.")
      return
    end

    status(:okay, "Processing image...")
    ImageProcessor.new(file, self)
  end
end
