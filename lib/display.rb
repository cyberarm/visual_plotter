class Display < Gosu::Window
  def initialize
    super(Gosu.screen_width/4*3, Gosu.screen_height/4*3, false)
    self.caption = "VisualPlotter version #{VisualPlotter::VERSION}"

    @machine = Machine.new
    @plot_button  = Button.new(window: self, text: "Print", x: 100, y: @machine.bed.y+@machine.bed.y) {@machine.plot}
    @close_button = Button.new(window: self, text: "Close", x: 100, y: @machine.bed.y+@machine.bed.y) {close}
  end

  def draw
    @machine.draw
    @plot_button.draw
    @close_button.draw
  end

  def update
    @machine.update
  end

  def needs_cursor?
    true
  end

  def button_up(id)
    case id
    when Gosu::KbEscape
      close
      # exit
    end
  end

  def drop(file)
    puts "FILE: #{file}"
    @machine.process_file(file)
  end
end
