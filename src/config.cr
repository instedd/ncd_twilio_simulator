struct Twiliosim::Config
  property no_reply_percent : Float64
  property delay_hang_up_seconds : Int32
  property delay_reply_min_seconds : Int32
  property delay_reply_max_seconds : Int32
  property incorrect_reply_percent : Float64
  property max_incorrect_reply_value : Int32
  property sticky_respondents : Bool

  def initialize
    @no_reply_percent = Config.float_env("NO_REPLY_PERCENT") || 0.0
    @delay_hang_up_seconds = Config.int_env("DELAY_HANG_UP_SECONDS") || 3
    @delay_reply_min_seconds = Config.int_env("DELAY_REPLY_MIN_SECONDS") || 1
    @delay_reply_max_seconds = Config.int_env("DELAY_REPLY_MAX_SECONDS") || 3
    @incorrect_reply_percent = Config.float_env("INCORRECT_REPLY_PERCENT") || 0.0
    @max_incorrect_reply_value = Config.int_env("MAX_INCORRECT_REPLY_VALUE") || 99
    @sticky_respondents = sticky_respondents?
  end

  def no_reply? : Bool
    @no_reply_percent >= rand
  end

  def incorrect_reply? : Bool
    @incorrect_reply_percent >= rand
  end

  def delay_reply_seconds : Time::Span
    rand(@delay_reply_min_seconds..@delay_reply_max_seconds).seconds
  end

  def delay_hang_up_seconds : Time::Span
    @delay_hang_up_seconds.seconds
  end

  def self.load : Twiliosim::Config
    Twiliosim::Config.new
  end

  protected def self.string_env(var_name : String) : String | Nil
    ENV[var_name] if ENV.has_key?(var_name)
  end

  protected def self.int_env(var_name : String) : Int32 | Nil
    if ENV.has_key?(var_name)
      value = string_env(var_name)
      return unless value
      value.to_i rescue raise "#{var_name} must be an integer"
    end
  end

  protected def self.float_env(var_name : String) : Float64 | Nil
    if ENV.has_key?(var_name)
      value = string_env(var_name)
      return unless value
      value.to_f rescue raise "#{var_name} must be a float"
    end
  end

  private def sticky_respondents? : Bool
    value = Config.string_env("STICKY_RESPONDENTS")
    return true unless value
    return value == "true"
  end
end
