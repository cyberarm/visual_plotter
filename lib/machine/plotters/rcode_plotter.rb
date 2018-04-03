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
        @pen.x = @bed.x
        @pen.y = @bed.y
      when "pen_up"
        @pen.plot = false
      when "pen_down"
        @pen.plot = true
      when "move"
        if @pen.plot
          y_target = @bed.y+instruction.y
          until(@pen.y == y_target)
            break unless @run
  
            if y_target > @pen.y
              @pen.y+=1
            else
              @pen.y-=1
            end
            @pen.paint
          end
  
          x_target = @bed.x+instruction.x
          until(@pen.x == x_target)
            break unless @run
  
            if x_target < @pen.x
              @pen.x-=1
              @pen.paint
            elsif x_target > @pen.x
              @pen.x+=1
              @pen.paint
            else
              raise "This should be impossible."
            end
          end
        else
          @pen.x = @bed.x+instruction.x
          @pen.y = @bed.y+instruction.y
        end
      end
    end
  end
end