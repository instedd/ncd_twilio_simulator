struct Twiliosim::Config
  # Percent of respondents that never reply
  property no_reply_percent : Float64
  # The time of waiting in seconds to hang up
  property unresponsive_timeout_seconds : Int32
  # Minimun time in seconds of that delay
  property delay_reply_min_seconds : Int32
  # Maximum time in seconds of that delay
  property delay_reply_max_seconds : Int32
  # Percent of respondents that reply an incorrect answer
  property incorrect_reply_percent : Float64
  # Maximum value replied as an incorrect answer
  property max_incorrect_reply_value : Int32
  # If true, once a respondent replies, it will always reply
  property sticky_respondents : Bool

  def initialize
    @no_reply_percent = Config.float_env("NO_REPLY_PERCENT")
    @unresponsive_timeout_seconds = Config.int_env("UNRESPONSIVE_TIMEOUT_SECONDS")
    @delay_reply_min_seconds = Config.int_env("DELAY_REPLY_MIN_SECONDS")
    @delay_reply_max_seconds = Config.int_env("DELAY_REPLY_MAX_SECONDS")
    @incorrect_reply_percent = Config.float_env("INCORRECT_REPLY_PERCENT")
    @max_incorrect_reply_value = Config.int_env("MAX_INCORRECT_REPLY_VALUE")
    @sticky_respondents = Config.string_env("STICKY_RESPONDENTS") == "true"
  end

  def self.load
    Twiliosim::Config.new
  end

  protected def self.string_env(var_name)
    unless (value = ENV[var_name]) && value != "***"
      raise "Missing #{var_name}"
    end
    value
  end

  protected def self.int_env(var_name)
    value = string_env(var_name)
    value.to_i rescue raise "#{var_name} must be an integer"
  end

  protected def self.float_env(var_name)
    value = string_env(var_name)
    value.to_f rescue raise "#{var_name} must be a float"
  end
end
