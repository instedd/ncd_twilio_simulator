require "../db"
require "../verboice"
require "../simulator"

module Twiliosim::CallController
  def self.handle_request(context : HTTP::Server::Context)
    params = HTTP::Params.parse(context.request.body.not_nil!.gets_to_end)

    # 1. create call
    call = Call.new(
      username: params["username"],
      to: params["to"],
      from: params["from"]
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
    context.response.status_code = 200
    context.response.content_type = "application/json"
    context.response << {
      "entries" => [{
        "sessionId" => call.id
      }]
    }.to_json
  end
end
