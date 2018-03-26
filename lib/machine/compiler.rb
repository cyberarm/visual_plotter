class Machine
  class Compiler
    Event = Struct.new(:type, :x, :y)
    def initialize
      @events = []
    end

    def add_event(type:, x:, y:)
      @events << Event.new(type, x, y)
    end

    def compile
    end
  end
end
