class Machine
  class Pen
    attr_accessor :x, :y, :plot
    def initialize(ghost: false, machine:, x: 100, y: 100, size: 4, color: Gosu::Color.rgb(100,100,25), down_color: Gosu::Color::BLACK)
      @ghost = ghost
      @machine = machine
      @bed = @machine.bed
      @x,@y,@size = x,y,size
      @color = color
      @down_color = down_color

      puts "PEN> #{@bed.width}x#{@bed.height}"

      @plot = false
    end

    def draw
      draw_rails
      Gosu.draw_rect(@x-@size/2.0, @y-@size/2.0, @size, @size, @color, 1000) unless @plot
      Gosu.draw_rect(@x-@size/2.0, @y-@size/2.0, @size, @size, @down_color, 1000) if @plot
    end

    def update
      @x = @bed.x+@bed.width-1 if @x > @bed.x+(@bed.width-1)
      @x = @bed.x if @x < @bed.x
      @y = @bed.y+@bed.height-1 if @y > @bed.y+(@bed.height-1)
      @y = @bed.y if @y < @bed.y

      if @plot
        paint
      end
    end

    def draw_rails
      if @ghost
        # X Axis
        Gosu.draw_rect(@bed.x, @y-1, @bed.width, 3, Gosu::Color.rgba(200, 0, 0, 100), 100)
        # Y Axis
        Gosu.draw_rect(@x-1, @bed.y, 3, @bed.height, Gosu::Color.rgba(0, 200, 0, 100), 100)
      else
        # X Axis
        Gosu.draw_rect(@bed.x, @y-1, @bed.width, 3, Gosu::Color.rgba(200, 0, 0, 200), 100)
        # Y Axis
        Gosu.draw_rect(@x-1, @bed.y, 3, @bed.height, Gosu::Color.rgba(0, 200, 0, 200), 100)
      end
    end

    def paint
      @machine.canvas.paint((@x-@bed.x), (@y-@bed.y), ChunkyPNG::Color::BLACK)
    end

    def bed_x
      @x-@bed.x
    end

    def bed_y
      @y-@bed.y
    end
  end
end
