abstract struct Twiliosim::SimulatorCommand
  def self.parse(message : String) : Twiliosim::SimulatorCommand | Nil
    Twiliosim::OneOfCommand.parse(message) || Twiliosim::NumericCommand.parse(message)
  end

  def valid_sample : Int32 | Nil
  end

  def invalid_sample(config : Twiliosim::Config) : Int32 | Nil
  end
end

struct Twiliosim::OneOfCommand < Twiliosim::SimulatorCommand
  property choices

  def initialize(@choices : Array(Int32))
  end

  def self.parse(message : String)
    if message =~ /#oneof:(\d+)(,\d+)*/
      /#oneof:(.+)/.match(message)
      choices = $~[1].split(',').map &.to_i
      Twiliosim::OneOfCommand.new choices
    end
  end

  def valid_sample : Int32
    @choices.sample
  end

  def invalid_sample(config : Twiliosim::Config) : Int32 | Nil
    # restrict candidates by config
    invalid_candidates = (0..config.max_incorrect_reply_value)
    # restrict candidates by command
    invalid_candidates = invalid_candidates.to_a.reject! { |x| @choices.includes?(x) }
    # pick a random candidate
    invalid_candidates.sample unless invalid_candidates.empty?
  end
end

struct Twiliosim::NumericCommand < Twiliosim::SimulatorCommand
  property min
  property max

  def initialize(@min : Int32, @max : Int32)
  end

  def self.parse(message : String) : NumericCommand | Nil
    if message =~ /#numeric:\s*(\d+)\s*-\s*(\d+)/
      min = $1.to_i
      max = $~[2].to_i
      Twiliosim::NumericCommand.new min, max
    end
  end

  def valid_sample : Int32
    rand(@min..@max)
  end

  def invalid_sample(config : Twiliosim::Config) : Int32 | Nil
    # restrict candidates by config
    invalid_candidates = (0..config.max_incorrect_reply_value)
    # restrict candidates by command
    invalid_candidates = invalid_candidates.to_a.reject!(@min..@max)
    # pick a random candidate
    invalid_candidates.sample unless invalid_candidates.empty?
  end
end
