class Button
  PADDING = 4
  def initialize(window:, text: "Button", x:, y:, color: Gosu::Color::RED, background: Gosu::Color.rgb(25,0,100), enabled: false, &block)
    @window = window
    @text = Text.new(text: @text, x: x, y:  y, color: color, size: 32)
    @x,@y = x,y
    @color, @background = color, background
    @hover = Gosu::Color.rgb(@background.red+10, @background.green+10, @background.blue+10)
    @enabled = false

    @block = block
  end

  def draw
    @text.draw
    if @enabled
      if mouse_over?
        Gosu.draw_rect(@x-PADDING, @y-PADDING, @text.width+PADDING, @text.size+PADDING, @hover)
      else
        Gosu.draw_rect(@x-PADDING, @y-PADDING, @text.width+PADDING, @text.size+PADDING, @background)
      end
    else
      Gosu.draw_rect(@x-PADDING, @y-PADDING, @text.width+PADDING, @text.size+PADDING, Gosu::Color::GRAY)
    end
  end

  def update
    if mouse_over?
      if @window.button_down?(Gosu::MsLeft)
        @block.call if @block
      end
    end
  end

  def mouse_over?
    if @window.mouse_x.between?(@x-PADDING, @x+@text.width+PADDING)
      if @window.mouse_x.between?(@x-PADDING, @x+@text.width+PADDING)
        true
      end
    end
  end
end
