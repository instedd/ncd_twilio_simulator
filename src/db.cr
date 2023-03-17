require "json"
require "./models/call"
require "mutex"

class Twiliosim::DB
  @calls = Hash(String, Twiliosim::Call).new
  @mutex = Mutex.new

  def create_call(to : String, from : String, @account_sid : String) : Twiliosim::Call
    call = Twiliosim::Call.new(to, from, account_sid)
    @mutex.synchronize { @calls[call.id] = call }
  end

  def update_call(call : Twiliosim::Call) : Twiliosim::Call
    @mutex.synchronize do
      raise "Cannot update an unexistent Call in DB - #{call.id}" unless @calls[call.id]
      @calls[call.id] = call
    end
  end
end
