require "json"
require "./controller"
require "../db"
require "../lib/bad_request_exception"
require "../models/reply_command"
require "../models/ao_message"
require "../models/respondent"

class Twiliosim::CallController < Twiliosim::Controller
  def initialize(context : HTTP::Server::Context, @account_sid : String)
    @db = Twiliosim::DB.get_instance()
    super(context)
  end

  def handle_request
    body_params = get_call_request_body_params(@context.request)
    from = body_params["from"]
    to = body_params["to"]
    verboice_url = body_params["verboice_url"]

    call = create_and_start_call(to, from, @account_sid)
    response_call_created(@context, call.id)
    spawn do
      # We give Verboice a sec to process the response. Just in case it needs it.
      sleep 1.seconds

      # verboice_url cannot be nil, so the `not_nil!` call shouldn't be here.
      # It's included here just because of [this Crystal compiler known issue](https://github.com/crystal-lang/crystal/issues/3093)
      handle_created_call(verboice_url.not_nil!, call)
    end
  end

  private def create_and_start_call(to : String, from : String, @account_sid : String) : TwilioCall
    call = @db.create_call(to, from, account_sid)
    call.start()
    @db.update_call(call)
  end

  private def finish_and_update_call(call : TwilioCall) : TwilioCall
    call.finish()
    @db.update_call(call)
  end

  private def get_call_request_body_params(request : HTTP::Request) : {to: String, from: String, verboice_url: String}
    params = get_validated_body_params(request, ["From", "To", "Url"])
    {to: params["To"], from: params["From"], verboice_url: params["Url"]}
  end

  private def get_validated_body_params(request : HTTP::Request, required_params : Array) : HTTP::Params
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

  private def response_call_created(context : HTTP::Server::Context, sid : String)
    context.response.status_code = 201
    context.response.content_type = "application/json"
    response = {sid: sid}
    response.to_json(context.response)
  end

  private def handle_created_call(verboice_url : String, call : TwilioCall) : ReplyCommand | Nil
    reply_command = call_verboice_and_reply_message(verboice_url, call, nil)
    return unless reply_command
    perform_response(reply_command, call)
  end

  private def call_verboice(verboice_url, call : TwilioCall, digits : Int32 | Nil) : String | Nil
    request_params = {"AccountSid" => call.account_sid, "From" => call.from, "To" => call.to, "CallStatus" => call.status}
    request_params["Digits"] = digits.to_s if digits
    request_body = HTTP::Params.encode(request_params)
    HTTP::Client.post(verboice_url, body: request_body) do |response|
      response_body = response.body_io.gets_to_end
      if response_body.blank?
        puts "Callback failed (body response is empty) - POST #{verboice_url} #{request_body} - #{response.status_code} - #{response.status_message}"
        return
      end
      response_body
    end
  end

  private def parse_ao_message(response_body : String) : TwilioAOMessage | Nil
    if %r(<Say .+>(.+)<\/Say>.*<Redirect>(.+)<\/Redirect>).match(response_body)
      message = $1
      redirect_url = $2
      TwilioAOMessage.new(message, redirect_url)
    end
  end

  private def ao_message_redirect_url(ao_message : TwilioAOMessage)
    ao_message.redirect_url
  end

  private def perform_response(reply_command : HangUp, call : TwilioCall) : ReplyCommand | Nil
    redirect_url = ao_message_redirect_url(reply_command.ao_message)
    call = finish_and_update_call(call)
    reply_command = call_verboice_and_reply_message(redirect_url, call, nil)
    return unless reply_command
    perform_response(reply_command, call)
  end

  private def perform_response(reply_command : PressDigits, call : TwilioCall) : ReplyCommand | Nil
    redirect_url = ao_message_redirect_url(reply_command.ao_message)
    reply_command = call_verboice_and_reply_message(redirect_url, call, reply_command.digits)
    return unless reply_command
    perform_response(reply_command, call)
  end

  private def call_verboice_and_reply_message(redirect_url : String, call : TwilioCall, digits : Int32 | Nil) : ReplyCommand | Nil
    response_body = call_verboice(redirect_url, call, digits)
    return unless response_body
    ao_message = parse_ao_message(response_body)
    return unless ao_message
    Respondent.reply_message(ao_message)
  end
end
