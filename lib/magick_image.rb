module Magick
  class Image
    def initialize(chunky_image)
      @chunky_image = chunky_image
    end

    def columns
      @chunky_image.width
    end

    def rows
      @chunky_image.height
    end

    def to_blob
      @chunky_image.to_rgba_stream
    end
  end
end
