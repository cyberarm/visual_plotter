class Machine
  class Plotter
    attr_accessor :invert, :threshold, :run, :forward, :steps
    def initialize(machine:)
      @machine = machine
      @pen     = machine.pen
      @bed     = machine.bed
      @compiler= machine.compiler

      @invert    = false
      @threshold = 90
      @run       = false
      @forward   = true
      @steps     = @machine.bed.width

      setup
    end

    def setup
    end

    def plot
    end

    def reset
    end

    # invert plotter color choices
    def invert_plotter
      @invert = !@invert
    end

    def threshold=int
      int = int.clamp(1, 255)
      @threshold = int
    end

    def steps=int
      int = int.clamp(1, (@bed.width*@bed.height).to_i)
      @steps = int
    end

    def pen_x
      @pen.x-@bed.x
    end

    def pen_y
      @pen.y-@bed.y
    end
  end
end