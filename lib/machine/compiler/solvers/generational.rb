class Machine
  class Compiler
    class Generational
      def initialize(canvas:)
        @canvas = canvas
        @lazy_solver_events = ClassicSolver.new(canvas: @canvas).path_events
        @nodes = []
        @next_generation = @nodes.shuffle
        @generation = 0
        @events= {pen_up: 0, pen_down: 0, move: 0}
        @event_count = @lazy_solver_events.count
        @compiler_events = []

        @canvas.image.height.to_i.times do |y|
          @canvas.image.width.to_i.times do |x|
            if ChunkyPNG::Color.r(@canvas.image[x,y]) <= 0
              @nodes << Machine::Plotter::Point.new(x, y)
            end
          end
        end

        until((@lazy_solver_events.count > @event_count)) # && @sameness >= @max_replicate)
          lets_take_a_journey
          that_leads_to_shortened_paths
        end
      end

      # Simulates plotter with generation and generate ranking
      def lets_take_a_journey
        puts "#{@generation} - #{@events}"
        @events[:pen_up] = 1
        @events[:pen_down] = 0
        @events[:move] = 0

        last_node = nil
        @next_generation.each do |node|
          if last_node
            @events[:move]+=1
          else
            @events[:move]+=1
          end
        end
      end

      # Ranks generation and decides whether to use this gen or murder it.
      def that_leads_to_shortened_paths
        # +1 is for the automatic home event
        @event_count = @events[:pen_down]+@events[:pen_up]+@events[:move]+1
        @generation+=1
      end

      def path_events
        @compiler_events
      end
    end
  end
end