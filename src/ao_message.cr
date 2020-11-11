abstract struct AOMessage
  getter message : String
  def initialize(@message : String)
  end
end

struct TwilioAOMessage < AOMessage
  getter redirect_url : String
  def initialize(message : String, @redirect_url : String)
    super(message)
  end
end
