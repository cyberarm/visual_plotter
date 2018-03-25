require_relative "machine/pen"
require_relative "machine/bed"
require_relative "machine/image_processor"

class Machine
  attr_reader :pen, :bed, :thread_safe_queue
  def initialize(width: 11*40, height: 8.5*40)
    @width, @height = width, height
    @bed = Bed.new(width: width, height: height)
    @pen = Pen.new(machine: self, x: @bed.x, y: @bed.y)
    @thread_safe_queue = []
    @bed_padding = 100

    @status_text = Text.new(text: "Status: Waiting for file...", x: @bed.x, y: 30, size: 24)
    @x_pos = Text.new(text: "X: ?", x: @bed.x+@bed.width/2, y: @bed.y-30)
    @y_pos = Text.new(text: "Y: ?", x: @bed.x+@bed.width+10, y: @bed.y+@bed.height/2)
    @pen_mode = Text.new(text: "Plot: false", x: @bed.x+@bed.width/2, y: @bed.y+@bed.height+10)
    @target = Text.new(text: "Target", x: @bed.x+@bed.width+@bed_padding+@bed.width/2, y: @bed.y-30)
  end

  def draw
    @bed.draw
    @pen.draw
    draw_rails

    @status_text.draw
    @x_pos.draw
    @y_pos.draw
    @pen_mode.draw
    @target.draw

    # @target_image.draw(0,0,100) if @target_image
    Gosu.draw_rect(@bed.x+@bed.width+@bed_padding, @bed.y, @bed.width, @bed.height, @bed.color)
    @target_image.draw(@bed.x+@bed.width+@bed_padding, @bed.y, 10) if @target_image
  end

  def draw_rails
    # X Axis
    Gosu.draw_rect(@pen.x-1, @bed.y-1, 3, @bed.height, Gosu::Color::CYAN)
    # Y Axis
    Gosu.draw_rect(@bed.x-1, @pen.y-1, @bed.width, 3, Gosu::Color::CYAN)
  end

  def update
    @pen.update
    # @bed.update
    @x_pos.text = "X: #{(@pen.x-@bed.x).round(2)}"
    @y_pos.text = "Y: #{(@pen.y-@bed.y).round(2)}"
    @pen_mode.text = "Plot: #{@pen.position == :down ? 'true' : 'false'}"

    @thread_safe_queue.pop.call if @thread_safe_queue.size > 0

    @pen.x+=1
    @pen.y+=1
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
    @target_image = Gosu::Image.new(Magick::Image.new(image))
    # @target_image = Gosu::Image.new("temp.png")
    # puts "IMAGE: #{@target_image.width}x#{@target_image.height}"
    # @target_image.save("post_test.png")
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
