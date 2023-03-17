require "json"
require "../db"
require "../lib/bad_request_exception"
require "../models/reply_command"
require "../models/ao_message"
require "../models/simulator"
require "../models/verboice"

module Twiliosim::CallController
  def self.handle_request(context : HTTP::Server::Context, account_sid : String, db : Twiliosim::DB, config : Twiliosim::Config)
    params = HTTP::Params.parse(context.request.body.not_nil!.gets_to_end)
    from = params["From"]
    to = params["To"]
    url = params["Url"]

    Log.info { "Call request - #{context.request.path} - From: #{from} - To: #{to} - Verboice Url: #{verboice_url}" }

    call = create_and_start_call(to, from, account_sid, db, config)
    response_call_created(context, call.id)

    spawn do
      # We give Verboice a sec to process the response. Just in case it needs it.
      sleep 2.seconds
      handle_created_call(url, call, db, config)
    end
  end

  private def self.create_and_start_call(to : String, from : String, account_sid : String, db : Twiliosim::DB, config : Twiliosim::Config) : Twiliosim::Call
    call = db.create_call(to, from, account_sid)
    # When sticky_respondents the no_reply setting applies once for all responses in the same call
    call.no_reply = config.no_reply? if config.sticky_respondents
    call.start
    call = db.update_call(call)
    Log.info { "Call started - sid: #{call.id} - account_sid: #{call.account_sid} - from: #{call.from} - to: #{call.to}" }
    call
  end

  private def self.response_call_created(context : HTTP::Server::Context, sid : String)
    context.response.status_code = 201
    context.response.content_type = "application/json"
    response = {sid: sid}
    response.to_json(context.response)
  end

  private def self.handle_created_call(verboice_url : String, call : Twiliosim::Call, db : Twiliosim::DB, config : Twiliosim::Config) : ReplyCommand | Nil
    reply_command = Orchestrator.post_and_reply(verboice_url, call, nil, config)
    return unless reply_command
    Orchestrator.perform_response(reply_command, call, db, config)
  end

  module Twiliosim::Orchestrator
    def self.post_and_reply(redirect_url : String, call : Twiliosim::Call, digits : Int32 | Nil, config : Twiliosim::Config) : ReplyCommand | Nil
      response_body = Twiliosim::Verboice.post(redirect_url, call.account_sid, call.from, call.to, call.status, digits)
      return unless response_body
      ao_message = parse_ao_message(response_body)
      return unless ao_message
      reply = Twiliosim::Simulator.reply_message(ao_message, config, no_reply?(call, config))
      Log.info { "Call reply - sid: #{call.id} - to: #{call.to} - Reply: #{reply.to_s} - AO message: #{ao_message.to_s}" }
      reply
    end

    private def self.no_reply?(call : Twiliosim::Call, config : Twiliosim::Config)
      if config.sticky_respondents
        call.no_reply
      else
        # When not sticky_respondents the no_reply setting applies differently for every response
        config.no_reply?
      end
    end

    def self.perform_response(reply_command : HangUp, call : Twiliosim::Call, db : Twiliosim::DB, config : Twiliosim::Config) : ReplyCommand | Nil
      call = finish_and_update_call(call, db)
      reply_command = post_and_reply(reply_command.ao_message.redirect_url, call, nil, config)
      return unless reply_command
      perform_response(reply_command, call, db, config)
    end

    def self.perform_response(reply_command : PressDigits, call : Twiliosim::Call, db : Twiliosim::DB, config : Twiliosim::Config) : ReplyCommand | Nil
      reply_command = post_and_reply(reply_command.ao_message.redirect_url, call, reply_command.digits, config)
      return unless reply_command
      perform_response(reply_command, call, db, config)
    end

    private def self.finish_and_update_call(call : Twiliosim::Call, db : Twiliosim::DB) : Twiliosim::Call
      call.finish
      call = db.update_call(call)
      Log.info { "Call finished - sid: #{call.id} - to: #{call.to}" }
      call
    end

    private def self.parse_ao_message(response_body : String) : Twiliosim::AOMessage | Nil
      if %r(<Say .+>(.+)<\/Say>.*<Redirect>(.+)<\/Redirect>).match(response_body)
        message = $1
        redirect_url = $2
        Twiliosim::AOMessage.new(message, redirect_url)
      end
    end
  end
end
