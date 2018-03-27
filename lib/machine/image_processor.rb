class Machine
  class ImageProcessor
    attr_reader :image, :ready
    def initialize(file, machine)
      @machine = machine
      @bed = machine.bed
      @file = file

      @machine.status(:okay, "Loading image into data structure...")
      @machine.update
      begin
        # NOTE: Gosu::Image is NOT thread safe, they'll be blank if queried from a thread.
        gosu_image = Gosu::Image.new(file)
        @image = ChunkyPNG::Image.from_rgba_stream(gosu_image.width, gosu_image.height, gosu_image.to_blob)
        gosu_image = nil

        Thread.new do
          process_image
          @machine.thread_safe_queue.clear
          @machine.thread_safe_queue << proc {@machine.image_ready(@image, @file)}
        end
      rescue NoMemoryError
        @machine.status(:error, "Ran out of them delicious bits. Try a smaller image.")
        @image = nil
        puts "Ran out of them delicious bits. :("
      end
    end

    def process_image
      @machine.thread_safe_queue << proc {@machine.status(:okay, "Scaling image...")}
      scale_image
      @machine.thread_safe_queue << proc {@machine.status(:okay, "Converting to grayscale...")}
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
