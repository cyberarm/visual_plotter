class Machine
  class ImageProcessor
    attr_reader :image, :ready
    def initialize(file, machine)
      @machine = machine
      @bed = machine.bed
      @file = file

      @machine.thread_safe_queue << proc {@machine.status(:busy, "Loading image into data structure...")}
      begin
        # NOTE: Gosu::Image is NOT thread safe, they'll be blank if queried from a thread.
        @machine.thread_safe_queue << proc {self.image_loaded(Gosu::Image.new(file)) }
        @machine.thread_safe_queue << proc {self.image_rgba_stream}

        Thread.new do
          until(@gosu_image && @image) do
            sleep 0.1
          end
          @gosu_image = nil

          process_image
          @machine.thread_safe_queue << proc {@machine.image_ready(@image, @file)}
        end
      rescue NoMemoryError
        @machine.status(:error, "Ran out of them delicious bits. Try a smaller image.")
        @gosu_image = nil
        @image = nil
        puts "Ran out of them delicious bits. :("
      end
    end

    def image_loaded(image)
      @gosu_image = image
    end

    def image_rgba_stream
      @image = ChunkyPNG::Image.from_rgba_stream(@gosu_image.width, @gosu_image.height, @gosu_image.to_blob)
    end

    def process_image
      @machine.thread_safe_queue << proc {@machine.status(:busy, "Scaling image...")}
      scale_image
      @machine.thread_safe_queue << proc {@machine.status(:busy, "Converting to grayscale...")}
      @image.grayscale!
    end

    def scale_image
      scale = [@bed.width.to_f/@image.width, @bed.height.to_f/@image.height].min
      puts "scale: #{scale}"
      width = @image.width * scale
      height = @image.height * scale

      puts "W #{width.to_i}, H #{height.to_i} -> #{scale}"
      @image.resample_bilinear!(width.to_i.clamp(1, @bed.width), height.to_i.clamp(1, @bed.height))
    end
  end
end
