require "http"
require "json"
require "uuid"
require "http/params"
require "./respondent.cr"
require "./call.cr"
require "./ao_message.cr"
require "./reply_command.cr"
require "./twiliosim_db.cr"
require "./bad_request_exception.cr"

module Twiliosim
  VERSION = "0.1.0"
end

class Twiliosim::Server
  delegate listen, close, to: @server
  getter address : Socket::Address

  def initialize(host, port)
    @server = HTTP::Server.new do |context|
      handle_request context
    end
    @address = @server.bind_tcp host, port

    @db = TwiliosimDB.new
  end

  def handle_request(context : HTTP::Server::Context)
    case context.request.path
    when %r(.+/IncomingPhoneNumbers.+)
      handle_incoming_phone_numbers_request(context)
    when %r(/Accounts/(.+)/Calls.*)
      account_sid = $1
      handle_call_request(context, account_sid)
    else
      context.response.respond_with_status(:not_found)
    end
  end

  private def handle_incoming_phone_numbers_request(context)
    context.response.status_code = 200
    context.response.content_type = "application/json"
    response = {"sid" => UUID.random().to_s()}
    response.to_json(context.response)
  end

  private def handle_call_request(context : HTTP::Server::Context, account_sid : String)
    unknown_error_message = "Internal error getting the request params"

    begin
      body_params = get_body_params(context.request.body, ["From", "To", "Url"])
    rescue ex: BadRequestException
      message = ex.message
      unless message
        puts "BadRequestException message is missing"
        raise unknown_error_message
      end
        plain_response(context, 400, message)
      return
    end

    from = body_params["From"]
    to = body_params["To"]
    verboice_url = body_params["Url"]

    unless from && to && verboice_url
      puts "Required (and validated) param is missing"
      raise unknown_error_message
    end

    call = create_and_start_call(to, from, account_sid)
    response_call_created(context, call.id)
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

  private def get_body_params(body : IO | Nil, required_params : Array) : HTTP::Params
    raise BadRequestException.new("Request body is missing") unless body
    body = body.gets_to_end
    raise BadRequestException.new("Request body is missing") unless body
    raise BadRequestException.new("Request body is missing") if body.blank?

    params = HTTP::Params.parse(body)
    required_params.map do |req_param|
      raise BadRequestException.new("Required param '{#{req_param}}' is missing in body") unless params.has_key?(req_param)
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

  private def plain_response(context : HTTP::Server::Context, code : Int32, text : String)
    context.response.status_code = code
    context.response.content_type = "text/plain"
    context.response.puts text
  end
end

server = Twiliosim::Server.new("0.0.0.0", ENV.fetch("PORT", "3000").to_i)
puts "Listening on #{server.address} ..."
server.listen
