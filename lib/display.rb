class Display < Gosu::Window
  def initialize
    super(Gosu.screen_width/4*3, Gosu.screen_height/4*3, fullscreen: false, update_interval: 50.0, resizable: true)

    self.caption = "VisualPlotter version #{VisualPlotter::VERSION}"
    @show_legal  = false
    @legal_text  = Gosu::LICENSES.split("\n")
    @text    = Text.new(size: 24)
    @escaped = 0

    @machine = Machine.new(window: self)#, width: 6*50, height: 4*50)
    @plot = Button.new(window: self, text: "Plot", x: 100, y: @machine.bed.y+@machine.bed.height+50, enabled: false) {@machine.replot}
    @save = Button.new(window: self, text: "Save Image", x: 180, y: @machine.bed.y+@machine.bed.height+50, enabled: false) {@machine.save}
    @compile = Button.new(window: self, text: "Compile", x: 360, y: @machine.bed.y+@machine.bed.height+50, enabled: false) {@machine.compile}
    Button.new(window: self, text: "Close", x: 500, y: @machine.bed.y+@machine.bed.height+50, background: Gosu::Color.rgb(128, 64, 0)) {close}

    @legal = Button.new(window: self, text: "Legal", x: @machine.bed.x, y: self.height-50) {@show_legal = !@show_legal}
    Button.new(window: self, text: "Open Data Folder", x: @machine.bed.x+100, y: self.height-50) {open_data_folder}
  end

  def open_data_folder
    if RUBY_PLATFORM =~ /mingw|cygwin|mswin/
      system("explorer \"#{Dir.pwd.gsub("/", "\\")}\\data\"")
    elsif RUBY_PLATFORM =~ /darwin/
      system("open \"#{Dir.pwd}/data\"")
    elsif RUBY_PLATFORM =~ /linux/
      system("xdg-open \"#{Dir.pwd}/data\"")
    else
      puts "unsupported platform."
    end
  end

  def render_legal
    Gosu.draw_rect(0, 0, self.width, self.height-100, Gosu::Color.rgba(10,10,10,250), 1001)
    @legal_text.each_with_index do |line, index|
      y = index*25
      @text.font.draw(line, 25, 100+y, 1002)
    end
  end

  def draw
    draw_rect(0, 0, self.width, self.height, Gosu::Color.rgb(15,15,15), -1)
    @machine.draw

    @legal.draw if @show_legal
    Button.list.each(&:draw) unless @show_legal

    render_legal if @show_legal
  end

  def update
    @legal.update if @show_legal
    unless @show_legal
      @machine.update
      @plot.enabled = (@machine.chunky_image || @machine.rcode_events) ? true : false
      @save.enabled = (@machine.chunky_image || @machine.rcode_events) && !@machine.plotter.run ? true : false
      @compile.enabled = ((@machine.pen.x != @machine.bed.x || @machine.pen.y != @machine.bed.y) && !@machine.plotter.run && !@machine.rcode_events) ? true : false
      Button.list.each(&:update)
    end
  end

  def needs_cursor?
    true
  end

  def button_up(id)
    _show_legal = @show_legal
    Button.list.each {|b| b.button_up(id)} unless @show_legal
    @legal.button_up(id) if (_show_legal == @show_legal) # Must be AFTER call to Button.list

    @machine.button_up(id)

    case id
    when Gosu::KbEscape
      @escaped += 1
      @show_legal = false
      close if @escaped > 1
    else
      @escaped = 0
    end
  end

  def drop(file)
    puts "FILE: #{file}"
    @machine.process_file(file)
  end
end
