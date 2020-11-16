require "./controllers/incoming_phone_numbers_controller.cr"
require "./controllers/call_controller.cr"

class Twiliosim::App
  include HTTP::Handler
  @db = Twiliosim::DB.new

  def call(context : HTTP::Server::Context)
    puts "Request received - #{context.request.path}"
    case context.request.path
    when %r(.+/IncomingPhoneNumbers.+)
      # When an incoming phone number requests is received, the response is 200
      puts "Incoming Phone Number (200) - #{context.request.path}"
      Twiliosim::IncomingPhoneNumbersController.handle_request(context)
    when %r(/Accounts/(.+)/Calls.*)
      account_sid = $1
      # Here is where all the magic happens
      Twiliosim::CallController.handle_request(context, account_sid, @db)
    else
      puts "NOT FOUND (404) - #{context.request.path}"
      call_next(context)
    end
  end
end
