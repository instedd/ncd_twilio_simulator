require "http"
require "./app"
require "log"

module Twiliosim
  VERSION = "0.1.0"

  Log = ::Log.for("twilio.simu")
end

Log.setup_from_env

server = HTTP::Server.new([
  HTTP::LogHandler.new,
  Twiliosim::App.new,
])

address = server.bind_tcp "0.0.0.0", ENV.fetch("PORT", "3000").to_i
puts "Listening on #{address} ..."
server.listen
