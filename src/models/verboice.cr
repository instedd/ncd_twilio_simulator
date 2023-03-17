module Twiliosim::Verboice
  def self.post(url, account_sid : String, from : String, to : String, call_status : String, digits : Int32 | Nil) : String | Nil
    request_params = {
      "AccountSid" => account_sid,
      "From" => from,
      "To" => to,
      "CallStatus" => call_status,
    }
    request_params["Digits"] = digits.to_s if digits
    request_body = HTTP::Params.encode(request_params)
    Log.info { "POST Request - #{url} - #{request_body}" }
    HTTP::Client.post(url, headers: HTTP::Headers{ "content-type" => "application/x-www-urlencoded" }, body: request_body) do |response|
      response_body = response.body_io.gets_to_end
      if response_body.blank?
        Log.error { "Callback failed (body response is empty) - POST #{url} - #{request_body} - #{response.status_code} - #{response.status_message}" }
        return
      end
      Log.info { "POST Response - #{url} - #{request_body} - #{response_body}" }
      response_body
    end
  end
end
