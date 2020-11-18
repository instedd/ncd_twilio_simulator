require "./simulator_command"

module Twiliosim::Simulator
  def self.reply_message(ao_message : AOMessage, config : Twiliosim::Config, no_reply : Bool) : ReplyCommand | Nil
    message = ao_message.message
    if message == "#hangup" || no_reply
      sleep config.delay_hang_up_seconds.seconds
      return HangUp.new(ao_message)
    end

    command = SimulatorCommand.parse(message)
    return unless command

    reply = if incorrect_reply?(config)
              command.invalid_sample(config)
            else
              command.valid_sample
            end
    return unless reply

    sleep delay_replay_seconds(config).seconds
    PressDigits.new(ao_message, reply)
  end

  private def self.delay_replay_seconds(config : Twiliosim::Config) : Int32
    rand(config.delay_reply_min_seconds..config.delay_reply_max_seconds)
  end

  private def self.incorrect_reply?(config : Twiliosim::Config) : Bool
    config.incorrect_reply_percent >= rand
  end
end
