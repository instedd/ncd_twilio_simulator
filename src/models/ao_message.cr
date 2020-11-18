struct Twiliosim::AOMessage
  getter message : String
  getter redirect_url : String

  def initialize(@message : String, @redirect_url : String)
  end

  def to_s : String
    "AOMessage - #{@redirect_url} - #{@message}"
  end
end
