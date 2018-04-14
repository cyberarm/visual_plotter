class Machine
  class Canvas
    BoundingBox = Struct.new(:min_x, :min_y, :max_x, :max_y)

    def initialize(machine:, x:, y:, width:, height:)
      @machine = machine
      @x,@y = x,y
      @width,@height = width,height
      @bounding_box = BoundingBox.new
      @bounding_box.min_x,@bounding_box.min_y, @bounding_box.max_x, @bounding_box.max_y = width,height, 0,0

      @chunky_image = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::WHITE)
      @image = nil
      puts "IMAGE> #{@chunky_image.width}x#{@chunky_image.height}"
      refresh
    end

    def paint(x, y, color = ChunkyPNG::Color::BLACK)
      raise "-1 index!" if x < 0 or y < 0
      unless @chunky_image.get_pixel(x,y) == nil
        @chunky_image[x,y] = color

        calculate_boundry(x,y)

        # puts "Write> #{x}x#{y} -> #{color}"
      else
        @machine.status(:error, "Pen target is outside of the canvas boundry, you may have a faulty rcode file.")
        @machine.plotter_run = false
        # puts "OutOfBounds> #{x}x#{y} -> #{color} | Machine plot: #{@machine.plotter_run}"
        return
      end
    end

    def calculate_boundry(x, y)
      @bounding_box.min_x = x if x < @bounding_box.min_x
      @bounding_box.min_y = y if y < @bounding_box.min_y

      @bounding_box.max_x = x if x > @bounding_box.max_x
      @bounding_box.max_y = y if y > @bounding_box.max_y
    end

    def save(filename)
      @chunky_image.crop(
        @bounding_box.min_x, @bounding_box.min_y,
        @bounding_box.max_x-@bounding_box.min_y, @bounding_box.max_y-@bounding_box.min_y
      ).save(filename)
    end

    def draw
      @image.draw(@x,@y,1)
    end

    def clear
      @chunky_image = nil
      @image = nil
    end

    def image
      @chunky_image
    end

    def refresh
      @image = Gosu::Image.new(Magick::Image.new(@chunky_image))
    end
  end
end
