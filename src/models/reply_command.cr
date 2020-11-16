require "./ao_message"

abstract struct Twiliosim::ReplyCommand
  getter ao_message : AOMessage

  def initialize(@ao_message)
  end

  def to_s : String
    ""
  end
end

struct Twiliosim::PressDigits < Twiliosim::ReplyCommand
  getter digits : Int32

  def initialize(ao_message, @digits)
    super(ao_message)
  end

  def to_s : String
    "PressDigits < ReplyCommand #{@digits.to_s}"
  end
end

struct Twiliosim::HangUp < Twiliosim::ReplyCommand
  def to_s : String
    "HangUp < ReplyCommand"
  end
end
