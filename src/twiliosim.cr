require "http"
require "./app"
require "./lib/bad_request_handler"
require "log"

module Twiliosim
  VERSION = "0.1.0"
end

server = HTTP::Server.new([
  Twiliosim::BadRequestHandler.new,
  Twiliosim::App.new,
])

address = server.bind_tcp "0.0.0.0", ENV.fetch("PORT", "3000").to_i
puts "Listening on #{address} ..."
server.listen
