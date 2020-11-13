require "./numeric_command"
require "./one_of_command"

module Twiliosim::Simulator
  def self.reply_message(ao_message : AOMessage) : ReplyCommand | Nil
    case ao_message.message
    when "#hangup"
      HangUp.new(ao_message)
    when /#numeric/
      numeric_command = NumericCommand.parse(ao_message.message)
      if numeric_command
        reply = numeric_command.sample
        PressDigits.new(ao_message, reply)
      end
    when /#oneof/
      one_of_command = OneOfCommand.parse(ao_message.message)
      if one_of_command
        reply = one_of_command.sample
        PressDigits.new(ao_message, reply)
      end
    end
  end
end
