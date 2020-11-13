abstract struct Twiliosim::AOMessage
  getter message : String
  def initialize(@message : String)
  end
end

struct Twiliosim::TwilioAOMessage < Twiliosim::AOMessage
  getter redirect_url : String
  def initialize(message : String, @redirect_url : String)
    super(message)
  end
end
