class Button
  PADDING = 4
  LIST = []
  def self.list
    LIST
  end

  attr_accessor :enabled
  def initialize(window:, text: "Button", x:, y:, color: Gosu::Color::WHITE, background: Gosu::Color.rgb(25,0,100), enabled: true, &block)
    @window = window
    @text = Text.new(text: text, x: x+PADDING, y:  y, z: 2, color: color, size: 32)
    @x,@y = x+PADDING,y
    @color, @background = color, background
    @hover = Gosu::Color.rgb(@background.red+50, @background.green+50, @background.blue+50)
    @enabled = enabled

    @block = block
    LIST << self
  end

  def draw
    @text.draw
    if @enabled
      if mouse_over?
        Gosu.draw_rect(@x-PADDING, @y-PADDING, @text.width+(PADDING*2), @text.size+PADDING, @hover)
      else
        Gosu.draw_rect(@x-PADDING, @y-PADDING, @text.width+(PADDING*2), @text.size+PADDING, @background)
      end
    else
      Gosu.draw_rect(@x-PADDING, @y-PADDING, @text.width+(PADDING*2), @text.size+PADDING, Gosu::Color.rgb(200,200,200))
    end
  end

  def update
  end

  def mouse_over?
    if @window.mouse_x.between?(@x-PADDING, @x+@text.width+PADDING)
      if @window.mouse_y.between?(@y-PADDING, @y+@text.size)
        true
      end
    end
  end

  def button_up(id)
    case id
    when Gosu::MsLeft
      if @enabled && mouse_over?
        puts "Button> #{@text.text} id: #{id}"
        @block.call if @block
      end
    end
  end
end
