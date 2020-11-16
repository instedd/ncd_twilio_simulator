struct OneOfCommand
  property choices

  def initialize(@choices : Array(Int32))
  end

  def self.parse(message : String)
    if message =~ /#oneof:(\d+)(,\d+)*/
      /#oneof:(.+)/.match(message)
      choices = $~[1].split(',').map &.to_i
      OneOfCommand.new choices
    end
  end

  def valid_sample : Int32
    @choices.sample
  end

  def invalid_sample(config)
    # restrict candidates by config
    invalid_candidates = (0..config.max_incorrect_reply_value)
    # restrict candidates by command
    invalid_candidates = invalid_candidates.to_a.reject! { |x| @choices.any?(x) }
    # pick a random candidate
    invalid_candidates.sample
  end
end
