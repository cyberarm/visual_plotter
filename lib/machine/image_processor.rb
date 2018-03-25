class Machine
  class ImageProcessor
    attr_reader :image, :ready
    def initialize(filename, machine)
      @machine = machine
      @bed = machine.bed
      Thread.new do
        begin
          @image = ChunkyPNG::Image.from_file(filename)
          process_image
          @machine.thread_safe_queue << proc {@machine.image_ready(@image)}
        rescue => e
          puts e
          @machine.status(:error, "Error: #{e.strip("\n")}")
        end
      end
    end

    def process_image
      @image.grayscale!
      scale_image
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
