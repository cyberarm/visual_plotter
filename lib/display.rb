class Display < Gosu::Window
  def initialize
    super(1400, Gosu.screen_height/4*3, fullscreen: false, update_interval: 50.0, resizable: true)

    self.caption = "VisualPlotter version #{VisualPlotter::VERSION}"
    @show_legal  = false
    @legal_text  = Gosu::LICENSES.split("\n")
    @text    = Text.new(size: 24)
    @escaped = 0

    @machine = Machine.new(window: self)
    @connection = nil
    @plot = Button.new(window: self, text: "Plot", x: 100, y: @machine.bed.y+@machine.bed.height+50, enabled: false) {@machine.replot}
    @save = Button.new(window: self, text: "Save Image", x: 180, y: @machine.bed.y+@machine.bed.height+50, enabled: false) {@machine.save}
    @compile = Button.new(window: self, text: "Compile", x: 360, y: @machine.bed.y+@machine.bed.height+50, enabled: false) {@machine.compile}
    Button.new(window: self, text: "Close", x: 500, y: @machine.bed.y+@machine.bed.height+50, background: Gosu::Color.rgb(128, 64, 0)) {close}

    if ARGV.join.include?("--network")
      at_exit do
        @connection.socket.close if @connection.connected?
      end
      @connect = Button.new(window: self, text: "Connect to Plotter", x: 100, y: @machine.bed.y+@machine.bed.height+100) do
        if @connection
          @connection.reconnect
        else
          if ARGV.join.include?("--test-server")
            @connection = Connection.new(host: "localhost", machine: @machine)
          else
            @connection = Connection.new(host: "192.168.49.1", machine: @machine)
          end
        end
      end
      @left_x  = Button.new(window: self, text: "←", x: 350, y: @machine.bed.y+@machine.bed.height+100, enabled: false, holdable: true, released: proc{@connection.request("move #{@machine.ghost_pen.bed_x*@connection.multiplier}:#{@machine.ghost_pen.bed_y*@connection.multiplier}"); @machine.status(:busy, "Moving to #{@machine.ghost_pen.bed_x*@connection.multiplier}:#{@machine.ghost_pen.bed_y*@connection.multiplier}"); @machine.canvas.refresh}) {@machine.ghost_pen.x-=1; @machine.pen.update; @machine.ghost_pen.update}
      @right_x = Button.new(window: self, text: "→", x: 380, y: @machine.bed.y+@machine.bed.height+100, enabled: false, holdable: true, released: proc{@connection.request("move #{@machine.ghost_pen.bed_x*@connection.multiplier}:#{@machine.ghost_pen.bed_y*@connection.multiplier}"); @machine.status(:busy, "Moving to #{@machine.ghost_pen.bed_x*@connection.multiplier}:#{@machine.ghost_pen.bed_y*@connection.multiplier}"); @machine.canvas.refresh}) {@machine.ghost_pen.x+=1; @machine.pen.update; @machine.ghost_pen.update}
      @up_y    = Button.new(window: self, text: "↑", x: 410, y: @machine.bed.y+@machine.bed.height+100, enabled: false, holdable: true, released: proc{@connection.request("move #{@machine.ghost_pen.bed_x*@connection.multiplier}:#{@machine.ghost_pen.bed_y*@connection.multiplier}"); @machine.status(:busy, "Moving to #{@machine.ghost_pen.bed_x*@connection.multiplier}:#{@machine.ghost_pen.bed_y*@connection.multiplier}"); @machine.canvas.refresh}) {@machine.ghost_pen.y-=1; @machine.pen.update; @machine.ghost_pen.update}
      @down_y  = Button.new(window: self, text: "↓", x: 440, y: @machine.bed.y+@machine.bed.height+100, enabled: false, holdable: true, released: proc{@connection.request("move #{@machine.ghost_pen.bed_x*@connection.multiplier}:#{@machine.ghost_pen.bed_y*@connection.multiplier}"); @machine.status(:busy, "Moving to #{@machine.ghost_pen.bed_x*@connection.multiplier}:#{@machine.ghost_pen.bed_y*@connection.multiplier}"); @machine.canvas.refresh}) {@machine.ghost_pen.y+=1; @machine.pen.update; @machine.ghost_pen.update}
      @home    = Button.new(window: self, text: "⌂", x: 470, y: @machine.bed.y+@machine.bed.height+100, enabled: false) {@machine.pen.x, @machine.pen.y = @machine.bed.x, @machine.bed.y; @connection.request("home"); ; @machine.status(:busy, "Moving to 0:0")}
      @pen_down= Button.new(window: self, text: "∙", x: 500, y: @machine.bed.y+@machine.bed.height+100, enabled: false) {@machine.pen.plot = true; @connection.request("pen_down"); @machine.status(:busy, "Lowering pen")}
      @pen_up  = Button.new(window: self, text: "°", x: 520, y: @machine.bed.y+@machine.bed.height+100, enabled: false) {@machine.pen.plot = false; @connection.request("pen_up"); @machine.status(:busy, "Raising pen")}
      @stop    = Button.new(window: self, text: "■", x: 545, y: @machine.bed.y+@machine.bed.height+100, enabled: false) {@connection.estop}
      @print   = Button.new(window: self, text: "Print", x: 580, y: @machine.bed.y+@machine.bed.height+100, enabled: false) {@connection.print_it}
    end

    @legal = Button.new(window: self, text: "Legal", x: @machine.bed.x, y: self.height-50) {@show_legal = !@show_legal}
    Button.new(window: self, text: "Open Data Folder", x: @machine.bed.x+100, y: self.height-50) {open_data_folder}
  end

  def network_buttons(boolean)
    list = [@left_x, @right_x, @up_y, @down_y, @pen_down, @pen_up, @home, @stop, @print]
    list.each {|b| b.enabled = boolean}
  end

  def plotter_status(response)
    data = response.split("\n")
    data.each do |r|
      s = r.split(":")
      case s.first.downcase
      when "time"
      when "pen"
        unless @machine.plotter.run
          @machine.pen.plot = true if s.last.to_f > 0
          @machine.pen.plot = false if s.last.to_f <= 0
        end
      when "x"
        @machine.pen.x = (s.last.to_i/@connection.multiplier)+@machine.bed.x unless @machine.plotter.run
      when "y"
        @machine.pen.y = (s.last.to_i/@connection.multiplier)+@machine.bed.y unless @machine.plotter.run
      when "x_endstop"
        @machine.x_endstop.triggered = true if s.last.strip == "true"
        @machine.x_endstop.triggered = false if s.last.strip != "true"
      when "y_endstop"
        @machine.y_endstop.triggered = true if s.last.strip == "true"
        @machine.y_endstop.triggered = false if s.last.strip != "true"
      end
    end
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
        @connect.text.text = "Plotter Connected"
        # @connection.request("status")
      elsif @connection && !@connection.connected?
        @connect.text.text = "Connect to Plotter"
      end

      if @connection && @connection.connected?
        if @last_request && Gosu.milliseconds-@last_request > 500
          @connection.request("status", self, :plotter_status)
          @last_request = Gosu.milliseconds
        end
        @last_request ||= Gosu.milliseconds
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
