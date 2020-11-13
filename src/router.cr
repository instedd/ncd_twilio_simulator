require "./controllers/incoming_phone_numbers_controller.cr"
require "./controllers/call_controller.cr"

class Twiliosim::Router
  include HTTP::Handler

  def call(context : HTTP::Server::Context)
    case context.request.path
    when %r(.+/IncomingPhoneNumbers.+)
      IncomingPhoneNumbersController.new(context).handle_request()
    when %r(/Accounts/(.+)/Calls.*)
      account_sid = $1
      CallController.new(context, account_sid).handle_request()
    else
      call_next(context)
    end
  end
end
