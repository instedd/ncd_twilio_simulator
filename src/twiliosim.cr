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
    when %r(/Accounts/(.+)/Calls.*)
      account_sid = $1
      body = request.body
      unless body
        plain_response(context, 400, "Request body is missing")
        return
      end
      body = body.gets_to_end
      unless body
        plain_response(context, 400, "Request body is missing")
        return
      end
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
        request_params = {"AccountSid" => account_sid, "From" => from, "To" => to, "CallStatus" => "in-progress"}
        request_body = HTTP::Params.encode(request_params)
        HTTP::Client.post(verboice_url, body: request_body) do |response|
          response_body = response.body_io.gets
          unless response_body
            puts "Callback failed (body response is empty) - POST #{verboice_url} #{request_body} - #{response.status_code} - #{response.status_message}"
            next
          end
          if response_body.blank?
            puts "Callback failed (body response is empty) - POST #{verboice_url} #{request_body} - #{response.status_code} - #{response.status_message}"
            next
          end
          case response_body
          when %r(<Redirect>(.*)<\/Redirect>)
            redirect_url = $1
            unless redirect_url
              puts "Callback failed (redirect url is missing) - POST #{verboice_url} #{request_body} - #{response.status_code} - #{response.status_message}"
              next
            end
            if %r(<Say language="en">hangup<\/Say>).matches?(response_body)
              spawn do
                sleep 5.seconds
                request_params["CallStatus"] = "completed"
                request_body = HTTP::Params.encode(request_params)
                HTTP::Client.post(redirect_url, body: request_body)
              end
            end
          else
            puts "Callback failed (redirect url is missing) - POST #{verboice_url} #{request_body} - #{response.status_code} - #{response.status_message}"
            next
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
