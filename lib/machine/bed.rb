class Machine
  class Bed
    attr_reader :x, :y, :width, :height
    def initialize(color: Gosu::Color::WHITE, x: 100, y: 100, width:, height:)
      @color = color
      @x,@y = x,y
      @width,@height = width,height
    end

    def draw
      Gosu.draw_rect(@x, @y, @width, @height, @color)
    end
  end
end
