require "http"
require "json"
require "uuid"
require "http/params"
require "./respondent.cr"
require "./call.cr"
require "./ao_message.cr"
require "./reply_command.cr"
require "./twiliosim_db.cr"

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
    request = context.request

    case request.path
    when %r(.+/IncomingPhoneNumbers.+)
      context.response.status_code = 200
      context.response.content_type = "application/json"
      response = {"sid" => UUID.random().to_s()}
      response.to_json(context.response)
    when %r(/Accounts/(.+)/Calls.*)
      account_sid = $1
      handle_call_request(context, account_sid)
    else
      plain_response(context, 404, "404 Not Found")
    end
  end

  private def handle_incoming_phone_numbers_request(context)
    context.response.status_code = 200
    context.response.content_type = "application/json"
    response = {"sid" => UUID.random().to_s()}
    response.to_json(context.response)
  end

  private def handle_call_request(context, account_sid)
    body_params = get_body_params(context.request.body)

    if (body_params["error"])
      plain_response(context, 400, body_params["error"])
      return
    end

    from = body_params["from"]
    to = body_params["to"]
    verboice_url = body_params["verboice_url"]

    unless from && to && verboice_url
      plain_response(context, 500, "Internal error getting the request params")
      return
    end

    call = TwilioCall.new(to, from, account_sid)
    call.start()
    @db.save_call(call)
    response_call_created(context, call.id)
    spawn do
      # We give Verboice a sec to process the response. Just in case it needs it.
      sleep 1.seconds

      # verboice_url cannot be nil, so the `not_nil!` call shouldn't be here.
      # It's included here just because of [this Crystal compiler known issue](https://github.com/crystal-lang/crystal/issues/3093)
      handle_created_call(verboice_url.not_nil!, call)
    end
  end

  private def get_body_params(body)
    unless body
      return { "error" => "Request body is missing" }
    end
    body = body.gets_to_end
    unless body
      return { "error" => "Request body is missing" }
    end
    if body.blank?
      return { "error" => "Request body is missing" }
    end
    params = HTTP::Params.parse(body)
    unless params.has_key?("Url")
      return { "error" => "Body param 'Url' is missing" }
    end
    verboice_url = params["Url"]
    unless params.has_key?("From")
      return { "error" => "Body param 'From' is missing" }
    end
    from = params["From"]
    unless params.has_key?("From")
      return { "error" => "Body param 'To' is missing" }
    end
    to = params["To"]

    { "to" => to, "from" => from, "verboice_url" => verboice_url, "error" => nil }
  end

  private def start_call(to, from, account_sid)
    @db.start_call(to, from, account_sid)
  end

  private def response_call_created(context, sid)
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
    request_params["Digits"] = digits.to_s if (digits)
    request_body = HTTP::Params.encode(request_params)
    HTTP::Client.post(verboice_url, body: request_body) do |response|
      empty_body_log = "Callback failed (body response is empty) - POST #{verboice_url} #{request_body} - #{response.status_code} - #{response.status_message}"
      response_body = response.body_io.gets
      unless response_body
        return
      end
      if response_body.blank?
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
    return unless redirect_url
    call.finish()
    @db.save_call(call)
    reply_command = call_verboice_and_reply_message(redirect_url, call, nil)
    return unless reply_command
    perform_response(reply_command, call)
  end

  private def perform_response(reply_command : PressDigits, call : TwilioCall) : ReplyCommand | Nil
    redirect_url = ao_message_redirect_url(reply_command.ao_message)
    return unless redirect_url
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

  private def plain_response(context, code, text)
    context.response.status_code = code
    context.response.content_type = "text/plain"
    context.response.puts text
  end
end

server = Twiliosim::Server.new("0.0.0.0", ENV.fetch("PORT", "3000").to_i)
puts "Listening on #{server.address} ..."
server.listen
