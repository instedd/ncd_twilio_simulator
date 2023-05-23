require "xml"
require "json"

struct Twiliosim::AOMessage
  struct GetDigits
    getter timeout : Int32
    getter num_digits : Int32?

    def self.new(node : XML::Node)
      if value = node["numDigits"]?
        num_digits = value == "infinity" ? Int32::MAX : value.to_i
      end
      new(node["timeout"].to_i, num_digits)
    end

    def initialize(@timeout : Int32, @num_digits : Int32?)
    end
  end

  include JSON::Serializable

  getter message : String
  getter received_at : Time

  @[JSON::Field(ignore: true)]
  @xml : XML::Node?

  def initialize(@message : String, @received_at = Time.utc)
  end

  def crashed? : Bool
    xml.xpath_float("count(//HTML)") > 0
  end

  def get_digits? : GetDigits?
    if node = xml.xpath_node("//GetDigits")
      GetDigits.new(node)
    end
  end

  def play? : String?
    xml.xpath_string("string(//Play[text()])").presence
  end

  def say? : String?
    xml.xpath_string("string(//Say[text()])").presence
  end

  def hangup? : Bool
    xml.xpath_float("count(//Say[text()='.'])") > 0
  end

  private def xml : XML::Node
    @xml ||= XML.parse(@message)
  end

  def inspect(io : IO) : Nil
    io << "#<AO received_at=#{@received_at} message=#{@message.inspect}>"
  end
end
