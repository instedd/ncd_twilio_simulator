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

  def valid_sample : Int32
    rand(@min..@max)
  end

  def invalid_sample(config)
    # restrict candidates by config
    invalid_candidates = (0..config.max_incorrect_reply_value)
    # restrict candidates by command
    invalid_candidates = invalid_candidates.to_a.reject!(@min..@max)
    # pick a random candidate
    invalid_candidates.sample
  end
end
