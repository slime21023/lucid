require "../../protocol/methods"
require "../../types/common"
require "../../types/logging"

module Mcp
  class Server
    module Handlers
      # Handles logging-related requests.
      class Logging
        # Handles `logging/setLevel`.
        def handle_set_level(server : Mcp::Server, request : Protocol::Request)
          params = request.params
          if params.nil?
            server.send_error(request.id, Protocol::Error::INVALID_PARAMS, "Missing params")
            return
          end

          level = params["level"]?.try &.as_s?
          if level.nil?
            server.send_error(request.id, Protocol::Error::INVALID_PARAMS, "Missing level")
            return
          end

          server.log_level = level
          server.send_result(request.id, Types::EmptyResult.new)
        end
      end
    end
  end
end
