require "http"
require "./router"
require "./lib/bad_request_handler"

module Twiliosim
  VERSION = "0.1.0"
end

server = HTTP::Server.new([
  Twiliosim::BadRequestHandler.new,
  Twiliosim::Router.new,
])

address = server.bind_tcp "0.0.0.0", ENV.fetch("PORT", "3000").to_i
puts "Listening on #{address} ..."
server.listen
