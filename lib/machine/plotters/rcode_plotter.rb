class Machine
  class RCodePlotter < Plotter
    def setup
      reset
    end

    def reset
      @rcode_index = 0
      @rcode_events = @machine.rcode_events
    end

    def stats
      ", rcode events: #{@rcode_index}/#{@rcode_events.size}"
    end

    def plot
      if @move_target
        if (pen_x != @move_target.x || pen_y != @move_target.y)
          unless pen_y == @move_target.y
            @pen.y-=1 if @move_target.y < pen_y
            @pen.y+=1 if @move_target.y > pen_y
          else
            @pen.x-=1 if @move_target.x < pen_x
            @pen.x+=1 if @move_target.x > pen_x
          end

          @pen.paint if @pen.plot
          return
        else
          @move_target = nil
        end
      end

      instruction = @rcode_events[@rcode_index]
      @rcode_index+=1
      if @rcode_index >= @rcode_events.size
        @run = false
        @machine.status(:okay, "Plotted rcode.")
        return
      end
      @machine.status(:busy, "Plotting from #{@machine.get_filename(@machine.rcode_file)}...")
      case instruction.type.downcase
      when "home"
        @move_target = Point.new(@bed.x, @bed.y)
      when "pen_up"
        @pen.plot = false
      when "pen_down"
        @pen.plot = true
        @pen.paint
      when "move"
        @move_target = Point.new(instruction.x, instruction.y)
      end
    end
  end
end