require "../../protocol/methods"
require "../../types/initialize"

module Mcp
  class Server
    module Handlers
      class Lifecycle
        def handle_initialize(server : Mcp::Server, request : Protocol::Request)
          result = Types::InitializeResult.new(
            protocol_version: "2024-11-05",
            capabilities: Types::Capabilities.new(
              tools: Types::ToolsCapabilities.new(list_changed: true),
              roots: nil
            ),
            server_info: Types::ServerInfo.new(
              name: "Crystal MCP SDK",
              version: Mcp::VERSION
            )
          )
          server.send_result(request.id, result)
        end

        def handle_initialized(_server : Mcp::Server, _notification : Protocol::Notification)
          # Hook point for lifecycle, currently no-op.
        end
      end
    end
  end
end
