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
      params = HTTP::Params.parse(request.body.not_nil!.gets_to_end)
      verboice_url = params["Url"]
      from = params["From"]
      to = params["To"]
      account_sid = (/\/Accounts\/(.+)\/Calls.*/.match(request.path).try &.[1]).not_nil!
      context.response.status_code = 201
      context.response.content_type = "application/json"
      response = {"sid" => UUID.random().to_s()}
      response.to_json(context.response)
      spawn do
        sleep 1.seconds
        HTTP::Client.post(verboice_url, body: "AccountSid=#{account_sid}&From=#{from}&To=#{to}&CallStatus=in-progress") do |response|
          body = response.body_io.gets.not_nil!
          verboice_url = (/<Redirect>(.*)<\/Redirect>/.match(body).try &.[1]).not_nil!
          hangup = /<Say language="en">hangup<\/Say>/.matches?(body)
          if hangup
            spawn do
              sleep 5.seconds
              HTTP::Client.post(verboice_url, body: "AccountSid=#{account_sid}&From=#{from}&To=#{to}&CallStatus=completed")
            end
          end
        end
      end
    when %r(^/add$)
      @nums << request.query_params["num"].to_i
      context.response.status_code = 200
      context.response.content_type = "text/plain"
      context.response.puts "ok"
    when %r(^/get$)
      context.response.status_code = 200
      @nums.to_json(context.response)
    else
      context.response.status_code = 404
      context.response.content_type = "text/plain"
      context.response.puts "404 Not Found"
    end
  end
end

server = Twiliosim::Server.new("0.0.0.0", ENV.fetch("PORT", "3000").to_i)
puts "Listening on #{server.address} ..."
server.listen
