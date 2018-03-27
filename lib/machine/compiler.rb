class Machine
  class Compiler
    Event = Struct.new(:type, :x, :y)

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
        @events << Event.new("move", pen_x, pen_y) if @events.size != 0
      when "pen_down"
        return if @pen_down
        @pen_down = true
        @events << Event.new("move", pen_x, pen_y)
      end

      @events << Event.new(type, x, y)
    end

    def pen_x
      @machine.pen.x-@machine.bed.x
    end

    def pen_y
      @machine.pen.y-@machine.bed.y
    end

    def compile(name = "compile")
      File.open("#{name}.rcode", "w") do |file|
        file.write "# Compiled at: #{Time.now.iso8601}\n"
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
