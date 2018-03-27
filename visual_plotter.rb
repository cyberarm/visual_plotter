require "time"
require "gosu"
begin
  require "oily_png"
rescue LoadError
  require "chunky_png"
end

Thread.abort_on_exception = true

require_relative "lib/version"
require_relative "lib/magick_image"
require_relative "lib/text"
require_relative "lib/button"
require_relative "lib/display"
require_relative "lib/machine"

Display.new.show
