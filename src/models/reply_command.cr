require "./ao_message"

abstract struct Twiliosim::ReplyCommand
  getter ao_message : AOMessage

  def initialize(@ao_message)
  end
end

struct Twiliosim::PressDigits < Twiliosim::ReplyCommand
  getter digits : Int32

  def initialize(ao_message, @digits)
    super(ao_message)
  end
end

struct Twiliosim::HangUp < Twiliosim::ReplyCommand
end
