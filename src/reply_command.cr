abstract struct ReplyCommand
  getter ao_message : AOMessage

  def initialize(@ao_message)
  end
end

struct PressDigits < ReplyCommand
  getter digits : Int32

  def initialize(ao_message, @digits)
    super(ao_message)
  end
end

struct HangUp < ReplyCommand
end
