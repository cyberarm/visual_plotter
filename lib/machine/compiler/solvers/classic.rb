class Machine
  class Compiler
    class ClassicSolver
      def initialize(canvas:)
        @canvas = canvas
        @compiler_events = []
        @pen_down = false
        @active_y = 0
        @last_x = 0

        add_event( Event.new("pen_up") )
        add_event( Event.new("home") )

        @canvas.image.height.to_i.times do |y|
          if @pen_down
            add_event( Event.new("move", @last_x, y-1) ) if @active_y < y
            add_event( Event.new("pen_up") ) if @active_y < y
            @pen_down = false if @active_y < y
          end

          @canvas.image.width.to_i.times do |x|
            if ChunkyPNG::Color.r(@canvas.image[x,y]) <= 0
              @last_x = x
              if !@pen_down
                @pen_down = true
                add_event( Event.new("move", x, y) )                
                add_event( Event.new("pen_down") )
              end
            else
              if @pen_down
                add_event( Event.new("move", x, y) )
                add_event( Event.new("pen_up") )
                @pen_down = false
              end
            end
          end
        end
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