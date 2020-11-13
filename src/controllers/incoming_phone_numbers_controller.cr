require "./controller"

class Twiliosim::IncomingPhoneNumbersController < Twiliosim::Controller
  def self.handle_request
    @context.response.status_code = 200
    @context.response.content_type = "application/json"
    response = {sid: UUID.random().to_s()}
    response.to_json(@context.response)
  end
end
