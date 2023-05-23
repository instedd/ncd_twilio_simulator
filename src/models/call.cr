require "json"
require "./ao_message"
require "./at_message"

class Twiliosim::Call
  include JSON::Serializable

  getter id : String
  getter username : String
  getter to : String
  getter from : String
  property no_reply : Bool
  property status : String
  getter messages : Array(AOMessage | ATMessage)

  def initialize(@to : String, @from : String, @username : String)
    @id = Random::DEFAULT.hex(4)
    @no_reply = false
    @status = "queued"
    @messages = [] of AOMessage | ATMessage
  end

  def <<(message : AOMessage | ATMessage)
    Log.info { "sid=#{@id} to=#{@to} message=#{message.inspect}" }
    @messages << message
  end

  def no_answer : Nil
    @status = "no-answer"
  end

  def in_progress : Nil
    @status = "in-progress"
  end

  def failed : Nil
    @status = "failed"
  end

  def completed : Nil
    @status = "completed"
  end

  def active? : Bool
    @status == "in-progress" || @status == "queued"
  end

  def no_reply?
    if App.config.sticky_respondents
      @no_reply
    else
      # when not sticky_respondents the setting applies differently for every response
      App.config.no_reply?
    end
  end

  def last_ao_message : AOMessage
    # @messages.reverse_each { |m| return m if m.is_a?(AOMessage) }.not_nil!
    @messages[-1].as(AOMessage)
  end

  def inspect(io : IO) : Nil
    io << "#<Call id=#{@id} to=#{@to} status=#{@status} messages=#{@messages.size}>"
  end
end
