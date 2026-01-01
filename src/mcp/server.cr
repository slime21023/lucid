require "./transport/transport"
require "./protocol/messages"
require "./protocol/methods"
require "./server/dsl"
require "./server/router"
require "./json_any"

module Mcp
  # MCP server that dispatches incoming JSON-RPC messages to capability handlers.
  #
  # Define tools by subclassing and using the DSL:
  #
  # ```crystal
  # class MyServer < Mcp::Server
  #   tool("add", "Adds two numbers", a: Int32, b: Int32) { |args| args.a + args.b }
  # end
  # ```
  class Server
    # Include the DSL module to enable 'tool' macro and registry
    include ServerDSL

    property transport : Mcp::Transport::Base
    @router : Router

    def initialize(@transport : Mcp::Transport::Base)
      @router = Router.new
      @transport.on_message = ->(msg : Protocol::Message) {
        handle_message(msg)
        nil
      }
    end

    # Starts the underlying transport read loop.
    def start
      @transport.start
    end

    # Closes the underlying transport.
    def close
      @transport.close
    end

    private def handle_message(message : Protocol::Message)
      case message
      when Protocol::Request
        @router.handle_request(self, message)
      when Protocol::Notification
        @router.handle_notification(self, message)
      when Protocol::Result
      when Protocol::Error
        STDERR.puts "Received error: #{message.error.message}"
      end
    end

    def send_result(id : (String | Int64 | Nil), result : JSON::Any)
      return if id.nil?
      res = Protocol::Result.new(result, id.not_nil!)
      @transport.send(res)
    end

    def send_result(id : (String | Int64 | Nil), payload : JSON::Serializable)
      send_result(id, Json.to_any(payload))
    end

    def send_error(id : (String | Int64 | Nil), code : Int32, message : String)
      return if id.nil?
      error_resp = Protocol::Error.new(
        Protocol::Error::ErrorData.new(code, message),
        id
      )
      @transport.send(error_resp)
    end
  end
end
