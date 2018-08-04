class Machine
  class EndStop
    attr_accessor :triggered
    attr_reader :x, :y, :axis
    def initialize(machine:, x:, y:, axis:, size: 10, color: nil, triggered_color: nil)
      @machine = machine
      @x, @y = x, y
      @axis = axis
      @size = size
      @triggered = false

      if color.nil? && triggered_color.nil?
        color_from_axis(@axis)
      else
        @color, @triggered_color = color, triggered_color
      end
    end

    def color_from_axis(axis)
      if axis == :x
        @color = Gosu::Color.rgba(200, 0, 0, 100)
        @triggered_color = Gosu::Color.rgba(200, 0, 0, 200)
      elsif axis == :y
        @color = Gosu::Color.rgba(0, 200, 0, 100)
        @triggered_color = Gosu::Color.rgba(0, 200, 0, 200)
      else
        raise "Unknown Axis"
      end
    end

    def draw
      puts @x, @y, @size, @color
      if @triggered
        Gosu.draw_rect(@x, @y, @size, @size, @triggered_color, 100)
      else
        Gosu.draw_rect(@x, @y, @size, @size, @color, 100)
      end
    end
  end
end