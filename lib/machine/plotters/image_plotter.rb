class Machine
  class ImagePlotter < Plotter
    def plot
      if  pen_y >= @machine.chunky_image.height-1
        @run = false
        @machine.status(:okay, "Plotting complete.")
      elsif @machine.chunky_image.get_pixel(pen_x, pen_y) &&
        (pen_x < @machine.chunky_image.width && pen_x < @bed.width)
        run_plotter
      else
        @pen.y+=1
      end
    end

    def run_plotter
      raise "Chunky Image is nil!" if @machine.chunky_image == nil;

      @machine.status(:busy, "Plotting...")
      color = ChunkyPNG::Color.r(@machine.chunky_image[pen_x, pen_y])

      if @invert
        @pen.plot = (color >= @threshold) ? true : false
      else
        @pen.plot = (color <= @threshold) ? true : false
      end

      @pen.update
      # NO PLOTTING OR EVENTS AFTER THIS LINE

      if @forward
        if (pen_x)+1 < @machine.chunky_image.width
          @pen.x+=1
        else
          @forward = false
          @pen.y+=1
        end
      else
        if (pen_x)-1 > 0
          @pen.x-=1
        else
          @forward = true
          @pen.x = @bed.x
          @pen.y+=1
        end
      end
    end
  end
end