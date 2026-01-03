require "./transport/transport"
require "./protocol/messages"
require "./protocol/methods"
require "./protocol/id"
require "./types/initialize"
require "./types/tools"
require "./types/content"
require "./types/common"
require "./types/logging"
require "./types/prompts"
require "./types/resources"
require "./types/roots"
require "./json_any"

module Mcp
  # MCP client over a `Mcp::Transport::Base`.
  #
  # Typical usage:
  # - `client = Mcp::Client.new(Mcp::Transport::Stdio.new)`
  # - `client.start`
  # - `client.connect("my-app", "0.1.0")`
  #
  # Typed response helpers decode `Protocol::Result#result` into `Mcp::Types::*`.
  #
  # This client can also act as the host side for certain server->host calls:
  # - Responds to `roots/list` requests (see `add_root` / `on_roots_list`)
  # - Receives `logging/message` notifications (see `on_logging_message`)
  class Client
    property transport : Mcp::Transport::Base

    # Roots advertised by this client when serving `roots/list`.
    getter roots : Array(Types::Root)

    # Simple ID counter for requests
    @request_id = 0_i64
    # Map of ID key to Channel for responses (id can be String or Int)
    @pending_requests = Hash(String, Channel(Protocol::Result | Protocol::Error)).new
    @on_roots_list : Proc(Types::RootsListResult)?
    @on_logging_message : Proc(Types::LoggingMessageParams, Nil)?

    def initialize(@transport : Mcp::Transport::Base)
      @roots = [] of Types::Root
      @on_roots_list = nil
      @on_logging_message = nil
      @transport.on_message = ->(msg : Protocol::Message) {
        handle_message(msg)
        nil
      }
    end

    # Starts the underlying transport read loop.
    def start
      @transport.start
    end

    # Performs MCP initialize handshake and sends `notifications/initialized`.
    def connect(name : String, version : String) : Protocol::Result | Protocol::Error
      params = Types::InitializeParams.new(
        protocol_version: "2024-11-05",
        capabilities: Types::Capabilities.new(
          roots: Types::RootsCapabilities.new(list_changed: true),
          tools: nil,
          resources: nil,
          prompts: nil,
          logging: nil
        ),
        client_info: Types::ClientInfo.new(name: name, version: version)
      )

      response = send_request(Protocol::Methods::INITIALIZE, Json.to_any(params))

      # We should also send 'notifications/initialized'
      send_notification(Protocol::Methods::NOTIFICATIONS_INITIALIZED)

      response
    end

    def connect_typed(name : String, version : String) : Types::InitializeResult | Protocol::Error
      decode_typed(connect(name, version), Types::InitializeResult)
    end

    # Requests `tools/list`.
    def list_tools : Protocol::Result | Protocol::Error
      send_request(Protocol::Methods::TOOLS_LIST)
    end

    def list_tools_typed : Types::ToolsListResult | Protocol::Error
      decode_typed(list_tools, Types::ToolsListResult)
    end

    # Requests `tools/call` with `arguments` encoded from a `Hash`/`NamedTuple`.
    def call_tool(name : String, args : Hash(String, _) | NamedTuple) : Protocol::Result | Protocol::Error
      params = Types::ToolsCallParams.new(
        name: name,
        arguments: JSON.parse(args.to_json)
      )
      send_request(Protocol::Methods::TOOLS_CALL, Json.to_any(params))
    end

    def call_tool_typed(name : String, args : Hash(String, _) | NamedTuple) : Types::ToolCallResult | Protocol::Error
      decode_typed(call_tool(name, args), Types::ToolCallResult)
    end

    # Requests `resources/list`.
    def list_resources : Protocol::Result | Protocol::Error
      send_request(Protocol::Methods::RESOURCES_LIST)
    end

    def list_resources_typed : Types::ResourcesListResult | Protocol::Error
      decode_typed(list_resources, Types::ResourcesListResult)
    end

    # Requests `resources/read`.
    #
    # Returns a `resources/read` JSON-RPC response where `result.contents` contains
    # one or more content items for the given URI.
    def read_resource(uri : String) : Protocol::Result | Protocol::Error
      params = Types::ResourcesReadParams.new(uri: uri)
      send_request(Protocol::Methods::RESOURCES_READ, Json.to_any(params))
    end

    def read_resource_typed(uri : String) : Types::ResourcesReadResult | Protocol::Error
      decode_typed(read_resource(uri), Types::ResourcesReadResult)
    end

    # Requests `prompts/list`.
    def list_prompts : Protocol::Result | Protocol::Error
      send_request(Protocol::Methods::PROMPTS_LIST)
    end

    def list_prompts_typed : Types::PromptsListResult | Protocol::Error
      decode_typed(list_prompts, Types::PromptsListResult)
    end

    # Requests `prompts/get`.
    #
    # `args` are passed through as the JSON-RPC `arguments` field.
    def get_prompt(name : String, args : JSON::Any? = nil) : Protocol::Result | Protocol::Error
      params = Types::PromptsGetParams.new(name: name, arguments: args)
      send_request(Protocol::Methods::PROMPTS_GET, Json.to_any(params))
    end

    def get_prompt(name : String, args : Hash(String, _) | NamedTuple) : Protocol::Result | Protocol::Error
      get_prompt(name, JSON.parse(args.to_json))
    end

    def get_prompt_typed(name : String, args : JSON::Any? = nil) : Types::PromptsGetResult | Protocol::Error
      decode_typed(get_prompt(name, args), Types::PromptsGetResult)
    end

    def get_prompt_typed(name : String, args : Hash(String, _) | NamedTuple) : Types::PromptsGetResult | Protocol::Error
      decode_typed(get_prompt(name, args), Types::PromptsGetResult)
    end

    # Sends `logging/setLevel`.
    #
    # The server may interpret this as the desired minimum log level for
    # subsequent `logging/message` notifications.
    def set_log_level(level : String) : Protocol::Result | Protocol::Error
      params = Types::LoggingSetLevelParams.new(level: level)
      send_request(Protocol::Methods::LOGGING_SET_LEVEL, Json.to_any(params))
    end

    def set_log_level_typed(level : String) : Types::EmptyResult | Protocol::Error
      decode_typed(set_log_level(level), Types::EmptyResult)
    end

    # Adds a root entry to be returned for incoming `roots/list` requests.
    def add_root(uri : String, name : String? = nil)
      @roots << Types::Root.new(uri: uri, name: name)
    end

    # Sets a handler for incoming `roots/list` requests.
    #
    # If unset, the client will respond with `roots` (as built via `add_root`).
    def on_roots_list(&block : -> Types::RootsListResult)
      @on_roots_list = block
    end

    # Sets a callback for incoming `logging/message` notifications.
    def on_logging_message(&block : Types::LoggingMessageParams -> Nil)
      @on_logging_message = block
    end

    private def next_id
      @request_id += 1
    end

    private def send_request(method : String, params : JSON::Any? = nil) : Protocol::Result | Protocol::Error
      id = next_id
      request = Protocol::Request.new(method, params, id)

      channel = Channel(Protocol::Result | Protocol::Error).new
      @pending_requests[id.to_s] = channel

      @transport.send(request)

      # Wait for response
      result = channel.receive
      @pending_requests.delete(id.to_s)

      result
    end

    private def send_notification(method : String, params : JSON::Any? = nil)
      notification = Protocol::Notification.new(method, params)
      @transport.send(notification)
    end

    private def handle_message(message : Protocol::Message)
      case message
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
          end
        end
      when Protocol::Request
        handle_request(message)
      when Protocol::Notification
        handle_notification(message)
      end
    end

    private def handle_request(request : Protocol::Request)
      case request.method
      when Protocol::Methods::ROOTS_LIST
        begin
          result =
            if handler = @on_roots_list
              handler.call
            else
              Types::RootsListResult.new(roots: @roots)
            end
          send_result(request.id, result)
        rescue ex
          send_error(request.id, Protocol::Error::INTERNAL_ERROR, ex.message || "roots/list failed")
        end
      else
        send_error(request.id, Protocol::Error::METHOD_NOT_FOUND, "Method #{request.method} not found")
      end
    end

    private def handle_notification(notification : Protocol::Notification)
      case notification.method
      when Protocol::Methods::LOGGING_MESSAGE
        params = notification.params
        return if params.nil?
        begin
          payload = Types::LoggingMessageParams.from_json(params.to_json)
          @on_logging_message.try &.call(payload)
        rescue
          # ignore malformed log notifications
        end
      else
        # ignore unknown notifications
      end
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

    private def send_result(id : (String | Int64 | Nil), payload : JSON::Serializable)
      return if id.nil?
      @transport.send(Protocol::Result.new(Json.to_any(payload), id.not_nil!))
    end

    private def send_error(id : (String | Int64 | Nil), code : Int32, message : String)
      error_resp = Protocol::Error.new(
        Protocol::Error::ErrorData.new(code, message),
        id
      )
      @transport.send(error_resp)
    end
  end
end
