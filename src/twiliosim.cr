require "http"
require "json"
require "uuid"
require "http/params"

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

    @nums = Array(Int32).new
  end

  def handle_request(context)
    request = context.request

    case request.path
    when %r(.+/IncomingPhoneNumbers.+)
      context.response.status_code = 200
      context.response.content_type = "application/json"
      response = {"sid" => UUID.random().to_s()}
      response.to_json(context.response)
    when %r(.+/Calls.*)
      account_sid = (/\/Accounts\/(.+)\/Calls.*/.match(request.path).try &.[1])
      unless account_sid
        plain_response(context, 400, "Account sid param is missing in the URL")
        return
      end
      unless request.body
        plain_response(context, 400, "Request body is missing")
        return
      end
      body = request.body.not_nil!.gets_to_end
      if body.blank?
        plain_response(context, 400, "Request body is missing")
        return
      end
      params = HTTP::Params.parse(body)
      unless params.has_key?("Url")
        plain_response(context, 400, "Body param 'Url' is missing")
        return
      end
      verboice_url = params["Url"]
      unless params.has_key?("From")
        plain_response(context, 400, "Body param 'From' is missing")
        return
      end
      from = params["From"]
      unless params.has_key?("From")
        plain_response(context, 400, "Body param 'To' is missing")
        return
      end
      to = params["To"]
      context.response.status_code = 201
      context.response.content_type = "application/json"
      response = {"sid" => UUID.random().to_s()}
      response.to_json(context.response)
      spawn do
        sleep 1.seconds
        request_body = "AccountSid=#{account_sid}&From=#{from}&To=#{to}&CallStatus=in-progress"
        HTTP::Client.post(verboice_url, body: request_body) do |response|
          response_body = response.body_io.gets
          unless response_body
            puts "Callback failed (body response is empty) - POST #{verboice_url} #{request_body} - #{response.status_code} - #{response.status_message}"
            next
          end
          response_body = response_body.not_nil!
          if body.blank?
            puts "Callback failed (body response is empty) - POST #{verboice_url} #{request_body} - #{response.status_code} - #{response.status_message}"
            next
          end
          redirect_regex = /<Redirect>(.*)<\/Redirect>/
          unless redirect_regex.matches?(response_body)
            puts "Callback failed (redirect url is missing) - POST #{verboice_url} #{request_body} - #{response.status_code} - #{response.status_message}"
            next
          end
          verboice_url = (redirect_regex.match(response_body).try &.[1]).not_nil!
          hangup = /<Say language="en">hangup<\/Say>/.matches?(response_body)
          if hangup
            spawn do
              sleep 5.seconds
              HTTP::Client.post(verboice_url, body: "AccountSid=#{account_sid}&From=#{from}&To=#{to}&CallStatus=completed")
            end
          end
        end
      end
    else
      plain_response(context, 404, "404 Not Found")
    end
  end
end

private def plain_response(context, code, text)
  context.response.status_code = code
  context.response.content_type = "text/plain"
  context.response.puts text
end

server = Twiliosim::Server.new("0.0.0.0", ENV.fetch("PORT", "3000").to_i)
puts "Listening on #{server.address} ..."
server.listen
