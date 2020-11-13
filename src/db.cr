require "./models/call"

class Twiliosim::DB
  @@instance = Twiliosim::DB.new
  @calls = Hash(String, TwilioCall).new

  def self.get_instance : Twiliosim::DB
    @@instance
  end

  def create_call(to : String, from : String, @account_sid : String) : TwilioCall
    call = TwilioCall.new(to, from, account_sid)
    @calls[call.id] = call
  end

  def update_call(call : TwilioCall) : TwilioCall
    raise "Cannot update an unexistent Call in DB - #{call.id}" unless @calls[call.id]
    @calls[call.id] = call
  end
end
