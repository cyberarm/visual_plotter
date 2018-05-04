class Machine
  class Compiler
    class Generational
      Node = Struct.new(:x, :y, :priority)
      def initialize(canvas:)
        @canvas = canvas
        @lazy_solver_events = ClassicSolver.new(canvas: @canvas).path_events
        @nodes = []
        @next_generation = @nodes.shuffle
        @generation = 0
        @max_generations = 100
        @event_count = @lazy_solver_events.count
        @compiler_events = []
        @ideal_path = false
        @point = Machine::Plotter::Point.new(0, 0)
        @recommended_nodes = nil
        @recommended_nodes_journey = 100_000_000_000

        @canvas.image.height.to_i.times do |y|
          @canvas.image.width.to_i.times do |x|
            if ChunkyPNG::Color.r(@canvas.image[x,y]) <= 0
              @nodes << Node.new(x, y, -100_000)
            end
          end
        end

        until(destination)
          lets_take_a_journey
          that_leads_to_shortened_paths
        end

        generate_events
      end

      def destination
        @ideal_path
      end

      def next_point
        if @point.x >= @canvas.image.width-1
          @point.x = 0
          @point.y+=10
        else
          @point.x+=10
        end
      end

      def lets_take_a_journey
        @journey = 0
        @nodes.each do |node|
          distance = Gosu.distance(@point.x, @point.y, node.x, node.y)
          node.priority = distance
          @journey+=distance
        end
        @nodes.sort_by! {|node| node.priority}
        puts "Journey: #{@journey.round} (#{@generation})"
        next_point
        @ideal_path = true if @generation >= @max_generations
      end

      # Ranks generation and decides whether to use this gen or murder it.
      def that_leads_to_shortened_paths
        if @journey < @recommended_nodes_journey
          @recommended_nodes_journey = @journey
          @recommended_nodes = @nodes
        end
        @generation+=1
      end

      def generate_events
        puts "Hello!"
        puts "Ideal journey found: #{@recommended_nodes_journey.round}"

        add_event( Event.new("pen_up") )
        add_event( Event.new("home") )

        @recommended_nodes.each do |node|
        add_event( Event.new("move", node.x, node.y) )
        end

        add_event( Event.new("pen_up") )
      end

      def add_event(event)
        @compiler_events << event
      end

      def path_events
        @compiler_events
      end
    end
  end
end