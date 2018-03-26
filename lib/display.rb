class Display < Gosu::Window
  def initialize
    super(Gosu.screen_width/4*3, Gosu.screen_height/4*3, false)
    self.caption = "VisualPlotter version #{VisualPlotter::VERSION}"

    @machine = Machine.new(window: self)#, width: 6*50, height: 4*50)
    Button.new(window: self, text: "Plot", x: 100, y: @machine.bed.y+@machine.bed.height+50) {@machine.replot}
    Button.new(window: self, text: "Save", x: 200, y: @machine.bed.y+@machine.bed.height+50) {@machine.save}
    Button.new(window: self, text: "Compile", x: 300, y: @machine.bed.y+@machine.bed.height+50) {}
    Button.new(window: self, text: "Close", x: 450, y: @machine.bed.y+@machine.bed.height+50) {close}
  end

  def draw
    @machine.draw

    Button.list.each(&:draw)
  end

  def update
    @machine.update
    Button.list.each(&:update)
  end

  def needs_cursor?
    true
  end

  def button_up(id)
    Button.list.each {|b| b.button_up(id)}

    case id
    when Gosu::KbI
      @machine.invert_plotter
    when Gosu::KbR
      @machine.plotter_run = !@machine.plotter_run
    when Gosu::KbS
      @machine.save if !@machine.plotter_run
    when Gosu::KbF5
      @machine.replot
    when Gosu::KbHome
      @machine.plotter_steps = @machine.bed.width
    when Gosu::KbEnd
      @machine.plotter_steps = 1
    when Gosu::KbEqual
      @machine.plotter_steps+=1
    when Gosu::KbMinus
      @machine.plotter_steps-=1
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
