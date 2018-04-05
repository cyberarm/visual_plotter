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
        add_event(type: "home", x: pen_x, y: pen_y) if @events.size != 0
      when "pen_down"
        return if @pen_down
        @pen_down = true
        add_event(type: "home", x: pen_x, y: pen_y)
      end

      @events << Event.new(type, x, y)
    end

    def pen_x
      @machine.pen.x-@machine.bed.x
    end

    def pen_y
      @machine.pen.y-@machine.bed.y
    end

    def compile(name = "compile-#{Time.now.strftime('%Y-%m-%d-%s')}")
      File.open("data/#{name}.rcode", "w") do |file|
        file.write "# Compiled at: #{Time.now.iso8601}\n"
        file.write "# Compiled with: inverted #{@machine.plotter.invert}, threshold #{@machine.plotter.threshold}\n"
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
