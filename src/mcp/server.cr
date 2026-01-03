require "./transport/transport"
require "./protocol/messages"
require "./protocol/methods"
require "./server/dsl"
require "./server/router"
require "./server/resources"
require "./server/prompts"
require "./json_any"
require "./types/logging"
require "./types/roots"

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
    getter resources : ResourceRegistry
    getter prompts : PromptRegistry
    getter log_level : String

    def initialize(@transport : Mcp::Transport::Base)
      @router = Router.new
      @resources = ResourceRegistry.new
      @prompts = PromptRegistry.new
      @log_level = "info"
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
        if id_key = Protocol::Id.key(message.id)
          if channel = @pending_requests[id_key]?
            channel.send(message)
          end
        end
      when Protocol::Error
        if id_key = Protocol::Id.key(message.id)
          if channel = @pending_requests[id_key]?
            channel.send(message)
            return
          end
        end
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

    def send_notification(method : String, params : JSON::Any? = nil)
      notification = Protocol::Notification.new(method, params)
      @transport.send(notification)
    end

    def send_notification(method : String, payload : JSON::Serializable)
      send_notification(method, Json.to_any(payload))
    end

    def log_level=(level : String)
      @log_level = level
    end

    def log_message(level : String, message : String, logger : String? = nil)
      send_notification(
        Protocol::Methods::LOGGING_MESSAGE,
        Types::LoggingMessageParams.new(level: level, message: message, logger: logger)
      )
    end

    def log_info(message : String, logger : String? = nil)
      log_message("info", message, logger)
    end

    def log_debug(message : String, logger : String? = nil)
      log_message("debug", message, logger)
    end

    def log_warn(message : String, logger : String? = nil)
      log_message("warn", message, logger)
    end

    def log_error(message : String, logger : String? = nil)
      log_message("error", message, logger)
    end

    # --- Server -> host requests (e.g. roots/list) ---
    @request_id = 0_i64
    @pending_requests = Hash(String, Channel(Protocol::Result | Protocol::Error)).new

    private def next_id
      @request_id += 1
    end

    def send_request(method : String, params : JSON::Any? = nil) : Protocol::Result | Protocol::Error
      id = next_id
      request = Protocol::Request.new(method, params, id)

      channel = Channel(Protocol::Result | Protocol::Error).new
      @pending_requests[id.to_s] = channel

      @transport.send(request)

      result = channel.receive
      @pending_requests.delete(id.to_s)

      result
    end

    def list_roots : Protocol::Result | Protocol::Error
      send_request(Protocol::Methods::ROOTS_LIST)
    end

    def list_roots_typed : Types::RootsListResult | Protocol::Error
      decode_typed(list_roots, Types::RootsListResult)
    end

    private def decode_typed(response : Protocol::Message, type : T.class) : T | Protocol::Error forall T
      case response
      when Protocol::Result
        begin
          T.from_json(response.result.to_json)
        rescue ex
          Protocol::Error.new(
            Protocol::Error::ErrorData.new(
              Protocol::Error::INTERNAL_ERROR,
              ex.message || "Failed to decode #{T}"
            ),
            response.id
          )
        end
      when Protocol::Error
        response
      else
        Protocol::Error.new(
          Protocol::Error::ErrorData.new(
            Protocol::Error::INTERNAL_ERROR,
            "Unexpected response type: #{response.class}"
          ),
          nil
        )
      end
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
