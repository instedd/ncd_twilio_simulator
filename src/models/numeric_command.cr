struct NumericCommand
  property min
  property max

  def initialize(@min : Int32, @max : Int32)
  end

  def self.parse(message : String) : NumericCommand | Nil
    if message =~ /#numeric:\s*(\d+)\s*-\s*(\d+)/
      min = $1.to_i
      max = $~[2].to_i
      NumericCommand.new min, max
    end
  end

  def sample : Int32
    rand(@min..@max)
  end
end
