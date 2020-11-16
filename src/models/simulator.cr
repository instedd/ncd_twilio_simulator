require "./numeric_command"
require "./one_of_command"

module Twiliosim::Simulator
  def self.reply_message(ao_message : AOMessage, config : Twiliosim::Config) : ReplyCommand | Nil
    case ao_message.message
    when "#hangup"
      HangUp.new(ao_message)
    when /#numeric/
      numeric_command = NumericCommand.parse(ao_message.message)
      if numeric_command
        reply = if incorrect_reply?(config)
          numeric_command.valid_sample
        else
          numeric_command.invalid_sample(config)
        end
        PressDigits.new(ao_message, reply)
      end
    when /#oneof/
      one_of_command = OneOfCommand.parse(ao_message.message)
      if one_of_command
        reply = if incorrect_reply?(config)
          one_of_command.valid_sample
        else
          one_of_command.invalid_sample(config)
        end
        PressDigits.new(ao_message, reply)
      end
    end
  end

  private def self.incorrect_reply?(config)
    config.incorrect_reply_percent >= rand
  end


end
