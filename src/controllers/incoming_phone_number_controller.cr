module Twiliosim::IncomingPhoneNumberController
  def self.handle_request(account_sid : String, sid : String, context : HTTP::Server::Context)
    context.response.status_code = 200
    context.response.content_type = "application/json"
    response = {
      "accountSid" => account_sid,
      "sid"        => sid,
    }
    response.to_json(context.response)
  end
end
