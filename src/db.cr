require "./models/call"

class Twiliosim::DB
  @calls = Hash(String, Twiliosim::Call).new

  def create_call(to : String, from : String, @account_sid : String) : Twiliosim::Call
    call = Twiliosim::Call.new(to, from, account_sid)
    @calls[call.id] = call
  end

  def update_call(call : Twiliosim::Call) : Twiliosim::Call
    raise "Cannot update an unexistent Call in DB - #{call.id}" unless @calls[call.id]
    @calls[call.id] = call
  end
end
