require "gosu"
begin
  require "oily_png"
rescue LoadError
  require "chunky_png"
end

Thread.abort_on_exception = true

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

class VisualPlotter
  VERSION = "1.0.0 Beta"
end

require_relative "lib/text"
require_relative "lib/button"
require_relative "lib/display"
require_relative "lib/machine"

Display.new.show
