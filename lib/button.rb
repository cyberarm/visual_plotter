class Button
  PADDING = 4
  LIST = []
  def self.list
    LIST
  end

  attr_accessor :enabled, :holdable
  attr_reader :text
  def initialize(window:, text: "Button", x:, y:, color: Gosu::Color::WHITE, background: Gosu::Color.rgb(50,50,150), enabled: true, holdable: false, released: nil, &block)
    @window = window
    @text = Text.new(text: text, x: x+PADDING, y:  y, z: 2, color: color, size: 32)
    @x,@y = x+PADDING,y
    @color, @background = color, background
    @hover = Gosu::Color.rgb(@background.red+50, @background.green+50, @background.blue+50)
    @enabled = enabled
    @holdable= holdable
    @holding = false

    @last_triggered = 0
    @trigger_point = 25 #ms

    @block = block
    @released = released
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
    if @holdable && @enabled && mouse_over? && Gosu.button_down?(Gosu::MsLeft)
      if Gosu.milliseconds-@last_triggered > @trigger_point
        @holding = true
        @block.call if @block

        @last_triggered = Gosu.milliseconds
      end
    elsif @holdable && @enabled && mouse_over? && !Gosu.button_down?(Gosu::MsLeft)
      if @holding
        @released.call if @released
      end
      @holding = false
    end
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
        if @holdable && Gosu.milliseconds-@last_triggered < @trigger_point
        else
          @block.call if @block
        end
      end
    end
  end
end
