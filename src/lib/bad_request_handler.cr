class Twiliosim::BadRequestHandler
  include HTTP::Handler
  def call(context : HTTP::Server::Context)
    begin
      call_next(context)
    rescue ex : BadRequestException
      context.response.respond_with_status(:bad_request, ex.message)
    end
  end
end
