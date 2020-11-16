abstract struct Twiliosim::AOMessage
  getter message : String
  def initialize(@message : String)
  end

  def to_s : String
    ""
  end
end

struct Twiliosim::TwilioAOMessage < Twiliosim::AOMessage
  getter redirect_url : String
  def initialize(message : String, @redirect_url : String)
    super(message)
  end

  def to_s : String
    "TwilioAOMessage - #{redirect_url} - #{message}"
  end
end
