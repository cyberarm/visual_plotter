class Machine
  class Compiler
    Event = Struct.new(:type, :x, :y)

    attr_reader :events, :pen_down, :same_y
    def initialize
      reset
    end

    def reset
      @events = []
      @pen_down = false
      @same_y = false
      @last_y = -1
    end

    def add_event(type:, x: nil, y: nil)
      case type
      when "pen_up"
        return if @pen_down == false && @events.size != 0
        @pen_down = false
      when "pen_down"
        return if @pen_down
        @pen_down = true
      when "move"
        raise "Missing X for move!" unless x.is_a?(Integer)
        raise "Missing Y for move!" unless y.is_a?(Integer)
        @same_y = false if @last_y != y
        @same_y = true if @last_y == y
        @last_y = y
        return if @pen_down
      end


      @events << Event.new(type, x, y)
    end

    def compile
      File.open("compile.rcode", "w") do |file|
        file.write "# Compiled at: #{Time.now.iso8601}\n"
        @events.each do |event|
          if event.x
            file.write "#{event.type} #{event.x}:#{event.y}\n"
          else
            file.write "#{event.type}\n"
          end
        end
      end
    end
  end
end
