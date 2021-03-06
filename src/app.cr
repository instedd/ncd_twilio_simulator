require "./controllers/incoming_phone_numbers_controller.cr"
require "./controllers/call_controller.cr"
require "./config"

class Twiliosim::App
  include HTTP::Handler
  @db = Twiliosim::DB.new
  @config = Twiliosim::Config.load

  def call(context : HTTP::Server::Context)
    Log.info { "Request received - #{context.request.path}" }
    case context.request.path
    when %r(.+/IncomingPhoneNumbers.+)
      # When an incoming phone number requests is received, the response is 200
      Log.info { "Incoming Phone Number (200) - #{context.request.path}" }
      Twiliosim::IncomingPhoneNumbersController.handle_request(context)
    when %r(/Accounts/(.+)/Calls.*)
      account_sid = $1
      # Here is where all the magic happens
      Twiliosim::CallController.handle_request(context, account_sid, @db, @config)
    else
      Log.warn { "NOT FOUND (404) - #{context.request.path}" }
      call_next(context)
    end
  end
end
