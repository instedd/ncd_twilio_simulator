struct Twiliosim::ATMessage
  include JSON::Serializable

  getter url : String
  getter status : String
  getter digits : String?
  getter sent_at : Time

  def initialize(@url, @status, digits, @sent_at = Time.utc)
    @digits = digits.to_s if digits
  end

  def inspect(io : IO) : Nil
    io << "#<AT sent_at=#{@sent_at} url=#{@url} status=#{@status} digits=#{@digits}>"
  end
end
