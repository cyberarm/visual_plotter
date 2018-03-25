class Machine
  class Pen
    attr_accessor :x, :y, :position
    def initialize(x: 100, y: 100, size: 4, color: Gosu::Color::GREEN, down_color: Gosu::Color::BLACK)
      @x,@y,@size = x,y,size
      @color = color
      @down_color = down_color

      @position = :up
    end

    def draw
      Gosu.draw_rect(@x-@size/2.0, @y-@size/2.0, @size, @size, @color) if @position == :up
      Gosu.draw_rect(@x-@size/2.0, @y-@size/2.0, @size, @size, @down_color) if @position == :down
    end
  end
end
