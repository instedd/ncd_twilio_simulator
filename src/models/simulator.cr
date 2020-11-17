require "./simulator_command"

module Twiliosim::Simulator
  def self.reply_message(ao_message : AOMessage, config : Twiliosim::Config) : ReplyCommand | Nil
    message = ao_message.message
    return HangUp.new(ao_message) if (message == "#hangup") || no_reply?(config)

    command = SimulatorCommand.parse(message)
    return unless command

    reply = if incorrect_reply?(config)
      command.invalid_sample(config)
    else
      command.valid_sample
    end
    return unless reply

    PressDigits.new(ao_message, reply)
  end

  private def self.no_reply?(config)
    config.no_reply_percent >= rand
  end

  private def self.incorrect_reply?(config)
    config.incorrect_reply_percent >= rand
  end


end
