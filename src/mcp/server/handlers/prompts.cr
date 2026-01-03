require "../../protocol/methods"
require "../../types/prompts"

module Mcp
  class Server
    module Handlers
      class Prompts
        def handle_list(server : Mcp::Server, request : Protocol::Request)
          list = server.prompts.values.map(&.prompt)
          server.send_result(request.id, Types::PromptsListResult.new(prompts: list))
        end

        def handle_get(server : Mcp::Server, request : Protocol::Request)
          params = request.params
          if params.nil?
            server.send_error(request.id, Protocol::Error::INVALID_PARAMS, "Missing params")
            return
          end

          name = params["name"]?.try &.as_s?
          if name.nil?
            server.send_error(request.id, Protocol::Error::INVALID_PARAMS, "Missing name")
            return
          end

          args = params["arguments"]?
          if defn = server.prompts[name]?
            begin
              result = defn.handler.call(args)
              server.send_result(request.id, result)
            rescue ex
              server.send_error(request.id, Protocol::Error::INTERNAL_ERROR, ex.message || "Prompt get failed")
            end
          else
            server.send_error(request.id, Protocol::Error::METHOD_NOT_FOUND, "Prompt #{name} not found")
          end
        end
      end
    end
  end
end

