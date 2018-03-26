class Machine
  class Pen
    attr_accessor :x, :y, :plot
    def initialize(machine:, x: 100, y: 100, size: 4, color: Gosu::Color.rgb(100,100,25), down_color: Gosu::Color::BLACK)
      @machine = machine
      @bed = @machine.bed
      @x,@y,@size = x,y,size
      @color = color
      @down_color = down_color

      puts "PEN> #{@bed.width}x#{@bed.height}"

      @plot = false
    end

    def draw
      Gosu.draw_rect(@x-@size/2.0, @y-@size/2.0, @size, @size, @color) unless @plot
      Gosu.draw_rect(@x-@size/2.0, @y-@size/2.0, @size, @size, @down_color) if @plot
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

    def paint
      @machine.canvas.paint((@x-@bed.x), (@y-@bed.y), ChunkyPNG::Color::BLACK)
    end
  end
end
