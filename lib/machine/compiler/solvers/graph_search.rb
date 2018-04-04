class Machine
  class Compiler
    class GraphSearchSolver
      def initialize(canvas:)
        @canvas = canvas
        @first_node = nil
        @known_nodes = []
        @canvas.image.height.to_i.times do |y|
          @canvas.image.width.to_i.times do |x|
            @known_nodes[x] = [] unless @known_nodes[x].is_a?(Array)
            if ChunkyPNG::Color.r(@canvas.image[x,y]) <= 0
              # :pending, :fuzzy?, :processed
              @known_nodes[x][y] = :pending
              @first_node = Node.new(x, y) unless @first_node
            end

            @known_nodes[x][y] = nil
          end
        end

        plan
      end

      def plan
        # Detect points and lines and create compiler instructions
      end

      def path_events
        p @known_nodes.flatten.compact
        p @known_nodes.flatten.compact.size
        []
      end
    end
  end
end