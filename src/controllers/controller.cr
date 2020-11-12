abstract class Twiliosim::Controller
  getter context : HTTP::Server::Context

  def initialize(@context)
  end

  def handle_request
  end
end
