class Twiliosim::Verboice
  def initialize(@call : Call)
    @url = "http://broker.verboice.lvh.me:8080/africas_talking"
  end

  def post(digits : Int32 | String | Nil = nil) : String
    params = {
      "isActive" => @call.active? ? "1" : "0",
      "sessionId" => @call.id,
      "direction" => "outbound",
      "destinationNumber" => @call.from,
      "callerNumber" => @call.to
    }
    params["dtmfDigits"] = digits.to_s if digits
    request_body = HTTP::Params.encode(params)
    headers = HTTP::Headers{ "content-type" => "application/x-www-urlencoded" }

    Log.trace { "POST url: #{@url} request: #{request_body} ..." }
    @call << ATMessage.new(@call.id, @call.status, digits)

    HTTP::Client.post(@url, headers: headers, body: request_body) do |response|
      response_body = response.body_io.gets_to_end

      Log.trace { "POST url: #{@url} request: #{request_body}\nheaders: #{response.headers}\nresponse: #{response_body}\n" }
      @call << AOMessage.new(response_body)

      response_body
    end
  end
end
