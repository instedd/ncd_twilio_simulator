require "uuid"

abstract class Twiliosim::Call
  property id : String
  property to : String
  property from : String

  def initialize(@to : String, @from : String)
    @id = UUID.random().to_s()
  end

  abstract def start
  abstract def finish
end

class Twiliosim::TwilioCall < Twiliosim::Call
  property account_sid : String
  property status : String

  def initialize(to : String, from : String, @account_sid : String)
    @status = "created"
    super(to, from)
  end

  def start
    @status = "in-progress"
  end

  def finish
    @status = "completed"
  end
end
