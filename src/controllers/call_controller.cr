require "json"
require "../db"
require "../lib/bad_request_exception"
require "../models/reply_command"
require "../models/ao_message"
require "../models/simulator"
require "../models/verboice"

module Twiliosim::CallController
  def self.handle_request(context : HTTP::Server::Context, account_sid : String, db : Twiliosim::DB, config : Twiliosim::Config)
    body_params = get_call_request_body_params(context.request)
    from = body_params["from"]
    to = body_params["to"]
    verboice_url = body_params["verboice_url"]

    Log.info { "Call request - #{context.request.path} - From: #{from} - To: #{to} - Verboice Url: #{verboice_url}" }

    call = create_and_start_call(to, from, account_sid, db)
    response_call_created(context, call.id)
    spawn do
      # We give Verboice a sec to process the response. Just in case it needs it.
      sleep 1.seconds

      # verboice_url cannot be nil, so the `not_nil!` call shouldn't be here.
      # It's included here just because of [this Crystal compiler known issue](https://github.com/crystal-lang/crystal/issues/3093)
      handle_created_call(verboice_url.not_nil!, call, db, config)
    end
  end

  private def self.create_and_start_call(to : String, from : String, account_sid : String, db : Twiliosim::DB) : TwilioCall
    call = db.create_call(to, from, account_sid)
    call.start
    call = db.update_call(call)
    Log.info { "Call started - sid: #{call.id} - account_sid: #{call.account_sid} - from: #{call.from} - to: #{call.to}" }
    call
  end

  private def self.get_call_request_body_params(request : HTTP::Request) : {to: String, from: String, verboice_url: String}
    params = get_validated_body_params(request, {"From", "To", "Url"})
    {to: params["To"], from: params["From"], verboice_url: params["Url"]}
  end

  private def self.get_validated_body_params(request : HTTP::Request, required_params : {String, String, String}) : HTTP::Params
    body = request.body
    raise BadRequestException.new("Missing request body") if body.nil?
    params = HTTP::Params.parse(body.gets_to_end)
    required_params.map do |req_param|
      param = params[req_param]?
      raise BadRequestException.new("Missing #{req_param}") if param.nil?
      raise BadRequestException.new("#{req_param} can't be blank") if param.blank?
    end
    params
  end

  private def self.response_call_created(context : HTTP::Server::Context, sid : String)
    context.response.status_code = 201
    context.response.content_type = "application/json"
    response = {sid: sid}
    response.to_json(context.response)
  end

  private def self.handle_created_call(verboice_url : String, call : TwilioCall, db : Twiliosim::DB, config : Twiliosim::Config) : ReplyCommand | Nil
    reply_command = Orchestrator.post_and_reply(verboice_url, call, nil, config)
    return unless reply_command
    Orchestrator.perform_response(reply_command, call, db, config)
  end

  module Orchestrator
    def self.post_and_reply(redirect_url : String, call : TwilioCall, digits : Int32 | Nil, config : Twiliosim::Config) : ReplyCommand | Nil
      response_body = Twiliosim::Verboice.post(redirect_url, call.account_sid, call.from, call.to, call.status, digits)
      return unless response_body
      ao_message = parse_ao_message(response_body)
      return unless ao_message
      reply = Twiliosim::Simulator.reply_message(ao_message, config)
      Log.info { "Call reply - sid: #{call.id} - to: #{call.to} - Reply: #{reply.to_s} - AO message: #{ao_message.to_s}" }
      reply
    end

    def self.perform_response(reply_command : HangUp, call : TwilioCall, db : Twiliosim::DB, config : Twiliosim::Config) : ReplyCommand | Nil
      redirect_url = ao_message_redirect_url(reply_command.ao_message)
      call = finish_and_update_call(call, db)
      reply_command = post_and_reply(redirect_url, call, nil, config)
      return unless reply_command
      perform_response(reply_command, call, db, config)
    end

    def self.perform_response(reply_command : PressDigits, call : TwilioCall, db : Twiliosim::DB, config : Twiliosim::Config) : ReplyCommand | Nil
      redirect_url = ao_message_redirect_url(reply_command.ao_message)
      reply_command = post_and_reply(redirect_url, call, reply_command.digits, config)
      return unless reply_command
      perform_response(reply_command, call, db, config)
    end

    private def self.finish_and_update_call(call : TwilioCall, db : Twiliosim::DB) : TwilioCall
      call.finish
      call = db.update_call(call)
      Log.info { "Call finished - sid: #{call.id} - to: #{call.to}" }
      call
    end

    private def self.parse_ao_message(response_body : String) : TwilioAOMessage | Nil
      if %r(<Say .+>(.+)<\/Say>.*<Redirect>(.+)<\/Redirect>).match(response_body)
        message = $1
        redirect_url = $2
        TwilioAOMessage.new(message, redirect_url)
      end
    end

    private def self.ao_message_redirect_url(ao_message : TwilioAOMessage)
      ao_message.redirect_url
    end
  end
end
