class Machine
  class Canvas
    def initialize(machine:, x:, y:, width:, height:)
      @machine = machine
      @x,@y = x,y
      @width,@height = width,height

      @chunky_image = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::WHITE)
      @image = nil
      puts "IMAGE> #{@chunky_image.width}x#{@chunky_image.height}"
      refresh
    end

    def paint(x, y, color = ChunkyPNG::Color::BLACK)
      raise "-1 index!" if x < 0 or y < 0
      unless @chunky_image.get_pixel(x,y) == nil
        @chunky_image[x,y] = color
        # puts "Write> #{x}x#{y} -> #{color}"
      else
        @machine.status(:error, "Pen target is outside of the canvas boundry, you may have a faulty rcode file.")
        @machine.plotter_run = false
        # puts "OutOfBounds> #{x}x#{y} -> #{color} | Machine plot: #{@machine.plotter_run}"
        return
      end
    end

    def save(filename)
      @image.save(filename)
    end

    def draw
      @image.draw(@x,@y,1)
    end

    def clear
      @chunky_image = nil
      @image = nil
    end

    def refresh
      @image = Gosu::Image.new(Magick::Image.new(@chunky_image))
    end
  end
end
