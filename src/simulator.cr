require "./models/reply_command"
require "./models/ao_message"
require "./models/simulator_command"

class Twiliosim::Simulator
  def self.spawn(call : Call) : Nil
    new(call).spawn
  end

  def initialize(@call : Call)
    @verboice = Verboice.new(@call)
  end

  def spawn : Nil
    ::spawn do
      loop do
        case @call.status
        when "queued"
          dial
        when "in-progress"
          process
        else
          break
        end
        App.db.update_call(@call)
      end
    rescue exception
      @call.failed
      App.db.update_call(@call)
    end
  end

  private def dial : Nil
    # simulate wait time until the phone is picked up
    # (really: give Verboice time to properly start the session)
    sleep 2.seconds

    if @call.no_reply?
      @call.no_answer
      # we don't report to Verboice (we might if `StatusCallbackEvent` was set & implemented by Verboice)
    else
      @call.in_progress
      @verboice.post(@call.url)
    end
  end

  private def process : Nil
    # handle previously received AO
    ao_message = @call.last_ao_message
    timeout = 5
    digits = nil

    raise "ERROR: remote server crashed." if ao_message.crashed?
    raise "ERROR: <Play> is unsupported; you must use <Say> (text-to-speech)." if ao_message.play?

    # received <Hangup>: hangup the call immediately
    if ao_message.hangup?
      @call.completed
      return
    end

    # received <Say>
    if cmd = ao_message.say?
      command = SimulatorCommand.parse(cmd)

      # received <Gather>
      if gather = ao_message.gather?
        timeout = gather.timeout
      end

      if command.is_a?(HangupCommand)
        # on #hangup:
        sleep(App.config.delay_hang_up_seconds)
        @call.completed
        return
      end

      if command
        # on #oneof or #numeric:
        digits = command.sample(App.config.incorrect_reply?, App.config.max_incorrect_reply_value)
      end
    end

    if redirect_url = ao_message.redirect?
      if @call.no_reply?
        sleep(timeout.seconds)
        @verboice.post(redirect_url, "timeout")
      else
        sleep(App.config.delay_reply_seconds)
        @verboice.post(redirect_url, digits)
      end
    else
      raise "ERROR: missing <Redirect> or <Hangup>; can't send timeout/pressed digits or terminate call."
    end
  end
end
