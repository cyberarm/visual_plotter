class Machine
  class Compiler
    Event = Struct.new(:type, :x, :y)

    def self.decompile(filename)
      instructions = []
      File.open(filename, "r") do |file|
        file.each_line do |line|
          line = line.strip
          list = line.split(" ")
          case list.first.downcase
          when "home"
            instructions << Event.new("home")
          when "pen_up"
            instructions << Event.new("pen_up")
          when "pen_down"
            instructions << Event.new("pen_down")
          when "move"
            coord = list.last.split(":")
            instructions << Event.new("move", Integer(coord.first), Integer(coord.last))
          end
        end
      end
      return instructions
    end

    attr_reader :events, :pen_down, :machine
    def initialize(machine:)
      @machine = machine
      reset
    end

    def reset
      @events = []
      @pen_down = false
      @last_event = Event.new("nil")
    end

    def add_event(type:, x: nil, y: nil)
      case type
      when "pen_up"
        return if @pen_down == false && @events.size != 0
        @pen_down = false
        add_adjusted_move if @events.size != 0
      when "pen_down"
        return if @pen_down
        @pen_down = true
        add_adjusted_move
      end

      @events << Event.new(type, x, y)
    end

    def pen_x
      @machine.pen.x-@machine.bed.x
    end

    def pen_y
      @machine.pen.y-@machine.bed.y
    end

    # Fix unwanted displacements
    def add_adjusted_move
      event = nil
      if @machine.plotter_forward
        if @machine.pen.x+1 >= @machine.bed.x+@machine.bed.width
          event = Event.new("move", pen_x, pen_y)
        else
          event = Event.new("move", pen_x-1, pen_y)
        end
      else
        if @machine.pen.x-1 <= @machine.bed.x
          event = Event.new("move", pen_x, pen_y)
        else
          if @machine.pen.x+1 >= @machine.bed.x+@machine.bed.width
            event = Event.new("move", pen_x, pen_y)
          else
            event = Event.new("move", pen_x+1, pen_y)
          end
        end
      end
      @events << event
    end

    def compile(name = "data/compile")
      File.open("#{name}.rcode", "w") do |file|
        file.write "# Compiled at: #{Time.now.iso8601}\n"
        file.write "# Compiled with: inverted #{@machine.invert_plotter}, threshold #{@machine.plotter_threshold}\n"
        @events.each do |event|
          if event.x
            file.write "#{event.type} #{event.x}:#{event.y}\n"
          else
            file.write "#{event.type}\n"
          end
        end
        file.write "pen_up"
      end
    end
  end
end
