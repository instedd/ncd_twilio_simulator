module Twiliosim::IncomingPhoneNumbersController
  def self.handle_request(account_sid : String, context : HTTP::Server::Context)
    context.response.status_code = 200
    context.response.content_type = "application/json"
    response = {
      "incoming_phone_numbers" => [
        {
          "accountSid" => account_sid,
          "sid" => "PN#{Random::DEFAULT.hex(4)}",
        }
      ]
    }
    response.to_json(context.response)
  end
end
