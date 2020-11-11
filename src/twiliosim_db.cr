class TwiliosimDB
  @calls = Hash(String, Call).new

  def save_call(call : Call) : Call
    @calls[call.id] = call
  end
end
