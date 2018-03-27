require "releasy"
require 'bundler/setup' # Releasy requires that your application uses bundler.
require_relative "lib/version"

Releasy::Project.new do
  name "VisualPlotter"
  version VisualPlotter::VERSION.gsub(" ", "_")

  executable "visual_plotter.rb"
  files ["lib/**/*.*", "data"]
  exclude_encoding # Applications that don't use advanced encoding (e.g. Japanese characters) can save build size with this.
  verbose

  add_build :windows_folder do
    executable_type :windows # Assuming you don't want it to run with a console window.
    add_package :exe # Windows self-extracting archive.
  end
end
