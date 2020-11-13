require "./controllers/incoming_phone_numbers_controller.cr"
require "./controllers/call_controller.cr"

class Twiliosim::App
  include HTTP::Handler
  @db = Twiliosim::DB.new

  def call(context : HTTP::Server::Context)
    case context.request.path
    when %r(.+/IncomingPhoneNumbers.+)
      Twiliosim::IncomingPhoneNumbersController.handle_request(context)
    when %r(/Accounts/(.+)/Calls.*)
      account_sid = $1
      Twiliosim::CallController.handle_request(context, account_sid, @db)
    else
      call_next(context)
    end
  end
end
