require "./config"
require "./controllers/*"

class Twiliosim::App
  include HTTP::Handler

  @@db = DB.load
  @@config = Twiliosim::Config.load

  def self.db : DB
    @@db
  end

  def self.config : Config
    @@config
  end

  def call(context : HTTP::Server::Context)
    case context.request.path
    when %r{/Accounts/(.+?)/IncomingPhoneNumbers/(.+?)\.json}
      Twiliosim::IncomingPhoneNumberController.handle_request($1, $2, context)

    when %r{/Accounts/(.+?)/IncomingPhoneNumbers\.json}
      Twiliosim::IncomingPhoneNumbersController.handle_request($1, context)

    when %r(/call.*)
      Twiliosim::CallController.handle_request(context)

    else
      context.response.status = :not_found
      context.response << "404 NOT FOUND"
    end

    context.response.flush
  end
end
