require "../../protocol/methods"
require "../../types/tools"
require "../../types/content"

module Mcp
  class Server
    module Handlers
      class Tools
        def handle_list(server : Mcp::Server, request : Protocol::Request)
          tools_list = server.registry.values.map do |tool_def|
            Types::Tool.new(
              name: tool_def.name,
              description: tool_def.description,
              input_schema: tool_def.inputSchema
            )
          end

          result = Types::ToolsListResult.new(tools: tools_list)
          server.send_result(request.id, result)
        end

        def handle_call(server : Mcp::Server, request : Protocol::Request)
          params = request.params
          if params.nil?
            server.send_error(request.id, Protocol::Error::INVALID_PARAMS, "Missing params")
            return
          end

          name = params["name"]?.try &.as_s?
          args = params["arguments"]?

          if name && (tool_def = server.registry[name]?) && (handler = tool_def.handler)
            spawn do
              begin
                result_data = handler.call(args)
                text = case result_data.raw
                       when String
                         result_data.as_s
                       else
                         result_data.to_json
                       end

                result = Types::ToolCallResult.new(
                  content: [Types::TextContent.new(text)]
                )
                server.send_result(request.id, result)
              rescue ex
                server.send_error(request.id, Protocol::Error::INTERNAL_ERROR, ex.message || "Tool execution failed")
              end
            end
          else
            server.send_error(request.id, Protocol::Error::METHOD_NOT_FOUND, "Tool #{name} not found")
          end
        end
      end
    end
  end
end
