require "gosu"
begin
  require "oily_png"
rescue LoadError
  require "chunky_png"
end

class VisualPlotter
  VERSION = "0.0.1alpha"
end

require_relative "lib/text"
require_relative "lib/button"
require_relative "lib/display"
require_relative "lib/machine"

Display.new.show
