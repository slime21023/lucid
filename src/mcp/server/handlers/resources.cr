require "../../protocol/methods"
require "../../types/resources"

module Mcp
  class Server
    module Handlers
      class Resources
        def handle_list(server : Mcp::Server, request : Protocol::Request)
          list = server.resources.values.map(&.resource)
          server.send_result(request.id, Types::ResourcesListResult.new(resources: list))
        end

        def handle_read(server : Mcp::Server, request : Protocol::Request)
          params = request.params
          if params.nil?
            server.send_error(request.id, Protocol::Error::INVALID_PARAMS, "Missing params")
            return
          end

          uri = params["uri"]?.try &.as_s?
          if uri.nil?
            server.send_error(request.id, Protocol::Error::INVALID_PARAMS, "Missing uri")
            return
          end

          if defn = server.resources[uri]?
            begin
              text = defn.handler.call
              content = Types::ResourceContent.new(uri: defn.resource.uri, mime_type: defn.resource.mime_type, text: text)
              server.send_result(request.id, Types::ResourcesReadResult.new(contents: [content]))
            rescue ex
              server.send_error(request.id, Protocol::Error::INTERNAL_ERROR, ex.message || "Resource read failed")
            end
          else
            server.send_error(request.id, Protocol::Error::METHOD_NOT_FOUND, "Resource #{uri} not found")
          end
        end
      end
    end
  end
end
