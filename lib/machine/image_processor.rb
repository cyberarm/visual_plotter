class Machine
  class ImageProcessor
    attr_reader :image, :ready
    def initialize(filename, machine, from_blob = false)
      @machine = machine
      @bed = machine.bed

      Thread.new do
        begin
          @machine.thread_safe_queue << proc {@machine.status(:okay, "Loading image into data structure...")}
          if from_blob
            @image = ChunkyPNG::Image.from_rgba_stream(filename.to_blob, filename.width, filename.height)
          else
            @image = ChunkyPNG::Image.from_file(filename)
          end
          process_image
          @machine.thread_safe_queue << proc {@machine.image_ready(@image)}
        rescue => e
          puts e
          @machine.status(:error, "Error: #{e.strip("\n")}")
        end
      end
    end

    def process_image
      @machine.thread_safe_queue << proc {@machine.status(:okay, "Scaling image...")}
      scale_image
      @machine.thread_safe_queue << proc {@machine.status(:okay, "Converting to grayscale...")}
      @image.grayscale!
      @image.save("test.png")
    end

    def scale_image
      width = @bed.width.to_f * @image.height.to_f / @image.width.to_f
      height = @bed.height.to_f * @image.height.to_f / @image.width.to_f
      puts "W #{width}, H #{height}"
      @image.resample_bilinear!(width.to_i, height.to_i)
    end
  end
end
