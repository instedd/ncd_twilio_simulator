require "./config"
require "./controllers/*"

class Twiliosim::App
  include HTTP::Handler

  @db = Twiliosim::DB.new
  @config = Twiliosim::Config.load

  def call(context : HTTP::Server::Context)
    case context.request.path
    when %r{/Accounts/(.+?)/IncomingPhoneNumbers/(.+?)\.json}
      Twiliosim::IncomingPhoneNumberController.handle_request($1, $2, context)

    when %r{/Accounts/(.+?)/IncomingPhoneNumbers\.json}
      Twiliosim::IncomingPhoneNumbersController.handle_request($1, context)

    when %r(/Accounts/(.+)/Calls.*)
      account_sid = $1
      Twiliosim::CallController.handle_request(context, account_sid, @db, @config)

    else
      context.response.status = :not_found
      context.response << "404 NOT FOUND"

      # call_next(context)
    end

    context.response.flush
  end
end
