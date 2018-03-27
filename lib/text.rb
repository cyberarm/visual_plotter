class Text
  CACHE = {}

  attr_accessor :text, :x, :y, :z, :color
  attr_reader :size, :font
  def initialize(text: "", x: 0, y: 0, z: 0, font: Gosu.default_font_name, size: 18, color: Gosu::Color::WHITE)
    @text    = text
    @x,@y,@z = x,y,z
    @font_name = font
    @size      = size
    @color     = color

    cache
  end

  def cache
    if CACHE[@font_name].is_a?(Hash)
      if CACHE[@font_name][@size]
        @font = CACHE[@font_name][@size]
      else
        CACHE[@font_name][@size] = Gosu::Font.new(@size, name: @font_name)
        @font = CACHE[@font_name][@size]
      end
    else
      CACHE[@font_name] = {}
      CACHE[@font_name][@size] = Gosu::Font.new(@size, name: @font_name)
      @font = CACHE[@font_name][@size]
    end
  end

  def width
    return @font.text_width(@text)
  end

  def draw
    @font.draw(@text, @x, @y, @z, 1, 1, @color)
  end
end
