require "uuid"

struct Twiliosim::Call
  property id : String
  property to : String
  property from : String
  property no_reply : Bool
  property account_sid : String
  property status : String

  def initialize(@to : String, @from : String, @account_sid : String)
    @id = UUID.random.to_s
    @no_reply = false
    @status = "created"
  end

  def start
    @status = "in-progress"
  end

  def finish
    @status = "completed"
  end
end
