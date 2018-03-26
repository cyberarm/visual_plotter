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
            @image = ChunkyPNG::Image.from_rgb_stream(filename.width, filename.height, filename.to_blob)
          else
            @image = ChunkyPNG::Image.from_file(filename)
          end
          process_image
          @machine.thread_safe_queue << proc {@machine.image_ready(@image)}
        # rescue => e
          # puts e
          # @machine.thread_safe_queue << proc {@machine.status(:error, "Error: #{e.to_s.strip}")}
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
      ratio =  @image.height.to_f / @image.width.to_f
      width = @bed.width.to_f * ratio
      height = @bed.height.to_f * ratio
      puts "W #{width.to_i}, H #{height.to_i} -> #{ratio}"
      @image.resample_bilinear!(width.to_i.clamp(1, @bed.width), height.to_i.clamp(1, @bed.height))
    end
  end
end
