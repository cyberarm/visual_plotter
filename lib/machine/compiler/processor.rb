class Machine
  class Compiler
    Node = Struct.new(:x, :y)

    class Processor
      def initialize(compiler:, canvas:, mode: :default)
        @compiler = compiler
        @canvas   = canvas

        case mode
        when :classic, :default
          default
        when :graph_search
          graph_search
        when :generational
          generational
        else
          raise "Unknown Processor Mode: #{mode}"
        end
      end

      def default
        solver = ClassicSolver.new(canvas: @canvas)
        @compiler.events << solver.path_events
        @compiler.events.flatten!
      end

      def graph_search
        solver = GraphSearchSolver.new(canvas: @canvas)
        @compiler.events << solver.path_events
        @compiler.events.flatten!
      end

      def generational
        solver = Generational.new(canvas: @canvas)
        @compiler.events << solver.path_events
        @compiler.events.flatten!
      end
    end
  end
end