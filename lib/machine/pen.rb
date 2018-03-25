class Machine
  class Pen
    attr_accessor :x, :y, :position
    def initialize(machine:, x: 100, y: 100, size: 4, color: Gosu::Color::GREEN, down_color: Gosu::Color::BLACK)
      @machine = machine
      @bed = @machine.bed
      @x,@y,@size = x,y,size
      @color = color
      @down_color = down_color

      puts "PEN> #{@bed.width}x#{@bed.height}"

      @position = :up
    end

    def draw
      Gosu.draw_rect(@x-@size/2.0, @y-@size/2.0, @size, @size, @color) if @position == :up
      Gosu.draw_rect(@x-@size/2.0, @y-@size/2.0, @size, @size, @down_color) if @position == :down
    end

    def update
      @x = @bed.x+@bed.width if @x > @bed.x+@bed.width-1
      @x = @bed.x if @x < @bed.x
      @y = @bed.y+@bed.height if @x > @bed.y+@bed.height-1
      @y = @bed.y if @x < @bed.y

      if @position == :down
        paint
      end
    end

    def paint
      @machine.canvas.paint((@x-@bed.x), (@y-@bed.y), ChunkyPNG::Color::BLACK)
    end
  end
end
