require "../protocol/methods"
require "./handlers/lifecycle"
require "./handlers/tools"
require "./handlers/resources"
require "./handlers/prompts"
require "./handlers/logging"

module Mcp
  class Server
    # Routes requests/notifications to capability handlers.
    class Router
      def initialize
        @lifecycle = Handlers::Lifecycle.new
        @tools = Handlers::Tools.new
        @resources = Handlers::Resources.new
        @prompts = Handlers::Prompts.new
        @logging = Handlers::Logging.new
      end

      def handle_request(server : Mcp::Server, request : Protocol::Request)
        case request.method
        when Protocol::Methods::INITIALIZE
          @lifecycle.handle_initialize(server, request)
        when Protocol::Methods::TOOLS_LIST
          @tools.handle_list(server, request)
        when Protocol::Methods::TOOLS_CALL
          @tools.handle_call(server, request)
        when Protocol::Methods::RESOURCES_LIST
          @resources.handle_list(server, request)
        when Protocol::Methods::RESOURCES_READ
          @resources.handle_read(server, request)
        when Protocol::Methods::PROMPTS_LIST
          @prompts.handle_list(server, request)
        when Protocol::Methods::PROMPTS_GET
          @prompts.handle_get(server, request)
        when Protocol::Methods::LOGGING_SET_LEVEL
          @logging.handle_set_level(server, request)
        else
          server.send_error(request.id, Protocol::Error::METHOD_NOT_FOUND, "Method #{request.method} not found")
        end
      end

      def handle_notification(server : Mcp::Server, notification : Protocol::Notification)
        case notification.method
        when Protocol::Methods::NOTIFICATIONS_INITIALIZED
          @lifecycle.handle_initialized(server, notification)
        else
          # ignore unknown notifications
        end
      end
    end
  end
end
