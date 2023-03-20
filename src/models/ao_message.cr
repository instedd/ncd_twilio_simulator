require "xml"
require "json"

struct Twiliosim::AOMessage
  struct Gather
    getter timeout : Int32
    getter num_digits : Int32?

    def self.new(node : XML::Node)
      new(node["timeout"].to_i, node["numDigits"]?.try(&.to_i))
    end

    def initialize(@timeout : Int32, @num_digits : Int32?)
    end
  end

  include JSON::Serializable

  getter message : String
  getter received_at : Time

  @[JSON::Field(ignore: true)]
  @twiml : XML::Node?

  def initialize(@message : String, @received_at = Time.utc)
  end

  def crashed? : Bool
    twiml.xpath_float("count(//HTML)") > 0
  end

  def gather? : Gather?
    if node = twiml.xpath_node("//Gather")
      Gather.new(node)
    end
  end

  def play? : String?
    twiml.xpath_string("string(//Play[text()])").presence
  end

  def say? : String?
    twiml.xpath_string("string(//Say[text()])").presence
  end

  def redirect? : String?
    twiml.xpath_string("string(//Redirect[text()])").presence
  end

  def hangup? : Bool
    twiml.xpath_float("count(//Hangup)") > 0
  end

  private def twiml : XML::Node
    @twiml ||= XML.parse(@message)
  end

  def inspect(io : IO) : Nil
    io << "#<AO received_at=#{@received_at} message=#{@message.inspect}>"
  end
end
