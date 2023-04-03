class Twiliosim::Verboice
  def initialize(@call : Call)
  end

  def post(url : String, digits : Int32 | String | Nil = nil) : String
    params = {
      "CallSid" => @call.id,
      "AccountSid" => @call.account_sid,
      "From" => @call.from,
      "To" => @call.to,
      "CallStatus" => @call.status,
    }
    params["Digits"] = digits.to_s if digits
    request_body = HTTP::Params.encode(params)
    headers = HTTP::Headers{ "content-type" => "application/x-www-urlencoded" }

    Log.trace { "POST url: #{url} request: #{request_body} ..." }
    @call << ATMessage.new(url, @call.status, digits)

    HTTP::Client.post(url, headers: headers, body: request_body) do |response|
      response_body = response.body_io.gets_to_end

      Log.trace { "POST url: #{url} request: #{request_body}\nheaders: #{response.headers}\nresponse: #{response_body}\n" }
      @call << AOMessage.new(response_body)

      response_body
    end
  end
end
