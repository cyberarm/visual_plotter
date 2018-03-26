class Display < Gosu::Window
  def initialize
    super(Gosu.screen_width/4*3, Gosu.screen_height/4*3, false)
    self.caption = "VisualPlotter version #{VisualPlotter::VERSION}"

    @machine = Machine.new(window: self)
    @plot_button  = Button.new(window: self, text: "Plot", x: 100, y: @machine.bed.y+@machine.bed.height+50) {@machine.plot}
    @close_button = Button.new(window: self, text: "Close", x: 200, y: @machine.bed.y+@machine.bed.height+50) {close}
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
    when Gosu::KbI
      @machine.invert_plotter
    when Gosu::KbR
      @machine.plotter_run = !@machine.plotter_run
    when Gosu::KbF5
      @machine.replot
    when Gosu::MsWheelUp
      @machine.plotter_threshold+=1
    when Gosu::MsWheelDown
      @machine.plotter_threshold-=1
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
