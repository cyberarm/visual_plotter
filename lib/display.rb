class Display < Gosu::Window
  def initialize
    super(Gosu.screen_width/4*3, Gosu.screen_height/4*3, fullscreen: false, update_interval: 50.0, resizable: true)

    self.caption = "VisualPlotter version #{VisualPlotter::VERSION}"
    @show_legal  = false
    @legal_text  = Gosu::LICENSES.split("\n")
    @text    = Text.new(size: 24)
    @escaped = 0

    @machine = Machine.new(window: self)#, width: 6*50, height: 4*50)
    @connection = nil
    @plot = Button.new(window: self, text: "Plot", x: 100, y: @machine.bed.y+@machine.bed.height+50, enabled: false) {@machine.replot}
    @save = Button.new(window: self, text: "Save Image", x: 180, y: @machine.bed.y+@machine.bed.height+50, enabled: false) {@machine.save}
    @compile = Button.new(window: self, text: "Compile", x: 360, y: @machine.bed.y+@machine.bed.height+50, enabled: false) {@machine.compile}
    Button.new(window: self, text: "Close", x: 500, y: @machine.bed.y+@machine.bed.height+50, background: Gosu::Color.rgb(128, 64, 0)) {close}

    if ARGV.join.include?("--network")
      @connect = Button.new(window: self, text: "Connect to Plotter", x: 100, y: @machine.bed.y+@machine.bed.height+100) {@connection ||= Connection.new(host: "localhost")}
      @left_x  = Button.new(window: self, text: "←", x: 350, y: @machine.bed.y+@machine.bed.height+100, enabled: false, holdable: true) {@machine.pen.x = @machine.pen.x-1; @machine.pen.update; @connection.request("move #{@machine.pen.x}:#{@machine.pen.y}")}
      @right_x = Button.new(window: self, text: "→", x: 380, y: @machine.bed.y+@machine.bed.height+100, enabled: false, holdable: true) {@machine.pen.x = @machine.pen.x+1; @machine.pen.update; @connection.request("move #{@machine.pen.x}:#{@machine.pen.y}")}
      @up_y    = Button.new(window: self, text: "↑", x: 410, y: @machine.bed.y+@machine.bed.height+100, enabled: false, holdable: true) {@machine.pen.y = @machine.pen.y-1; @machine.pen.update; @connection.request("move #{@machine.pen.x}:#{@machine.pen.y}")}
      @down_y  = Button.new(window: self, text: "↓", x: 440, y: @machine.bed.y+@machine.bed.height+100, enabled: false, holdable: true) {@machine.pen.y = @machine.pen.y+1; @machine.pen.update; @connection.request("move #{@machine.pen.x}:#{@machine.pen.y}")}
      @home    = Button.new(window: self, text: "⌂", x: 470, y: @machine.bed.y+@machine.bed.height+100, enabled: false) {@machine.pen.x, @machine.pen.y = @machine.bed.x, @machine.bed.y; @connection.request("home")}
      @pen_down= Button.new(window: self, text: "∙", x: 500, y: @machine.bed.y+@machine.bed.height+100, enabled: false) {@machine.pen.plot = true; @connection.request("pen_down")}
      @pen_up  = Button.new(window: self, text: "°", x: 520, y: @machine.bed.y+@machine.bed.height+100, enabled: false) {@machine.pen.plot = false; @connection.request("pen_up")}
      @stop    = Button.new(window: self, text: "■", x: 545, y: @machine.bed.y+@machine.bed.height+100, enabled: false) {@connection.request("stop")}
    end

    @legal = Button.new(window: self, text: "Legal", x: @machine.bed.x, y: self.height-50) {@show_legal = !@show_legal}
    Button.new(window: self, text: "Open Data Folder", x: @machine.bed.x+100, y: self.height-50) {open_data_folder}
  end

  def network_buttons(boolean)
    list = [@left_x, @right_x, @up_y, @down_y, @pen_down, @pen_up, @home, @stop]
    list.each {|b| b.enabled = boolean}
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
      network_buttons(@connection.connected?) if @connection
      if @connection && @connection.connected?
        # @connection.request("status")
      end
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
