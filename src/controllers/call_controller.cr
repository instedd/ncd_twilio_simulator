require "../db"
require "../verboice"
require "../simulator"

module Twiliosim::CallController
  def self.handle_request(context : HTTP::Server::Context, account_sid : String)
    params = HTTP::Params.parse(context.request.body.not_nil!.gets_to_end)

    # 1. create call
    call = Call.new(
      account_sid: account_sid,
      to: params["To"],
      from: params["From"],
      url: params["Url"],
    )
    if App.config.sticky_respondents
      # with sticky_respondents the no_reply setting applies once for all responses in the same call
      call.no_reply = App.config.no_reply?
    end

    App.db.create_call(call)
    # Log.info { call.inspect }

    # 2. spawn simulator to handle the call
    Simulator.spawn(call)

    # 3. respond to caller
    context.response.status_code = 201
    context.response.content_type = "application/json"
    context.response << {sid: call.id}.to_json
  end
end
