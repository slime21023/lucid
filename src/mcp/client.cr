require "./transport/transport"
require "./protocol/messages"
require "./protocol/methods"
require "./protocol/id"
require "./types/initialize"
require "./types/tools"
require "./types/content"
require "./json_any"

module Mcp
  # MCP client over a `Mcp::Transport::Base`.
  #
  # Typical usage:
  # - `client = Mcp::Client.new(Mcp::Transport::Stdio.new)`
  # - `client.start`
  # - `client.connect("my-app", "0.1.0")`
  #
  # For typed responses, use `connect_typed`, `list_tools_typed`, and
  # `call_tool_typed`.
  class Client
    property transport : Mcp::Transport::Base

    # Simple ID counter for requests
    @request_id = 0_i64
    # Map of ID key to Channel for responses (id can be String or Int)
    @pending_requests = Hash(String, Channel(Protocol::Result | Protocol::Error)).new

    def initialize(@transport : Mcp::Transport::Base)
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
    def connect(name : String, version : String)
      params = Types::InitializeParams.new(
        protocol_version: "2024-11-05",
        capabilities: Types::Capabilities.new(
          roots: Types::RootsCapabilities.new(list_changed: true),
          tools: nil
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
    def list_tools
      send_request(Protocol::Methods::TOOLS_LIST)
    end

    def list_tools_typed : Types::ToolsListResult | Protocol::Error
      decode_typed(list_tools, Types::ToolsListResult)
    end

    # Requests `tools/call` with `arguments` encoded from a `Hash`/`NamedTuple`.
    def call_tool(name : String, args : Hash(String, _) | NamedTuple)
      params = Types::ToolsCallParams.new(
        name: name,
        arguments: JSON.parse(args.to_json)
      )
      send_request(Protocol::Methods::TOOLS_CALL, Json.to_any(params))
    end

    def call_tool_typed(name : String, args : Hash(String, _) | NamedTuple) : Types::ToolCallResult | Protocol::Error
      decode_typed(call_tool(name, args), Types::ToolCallResult)
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
        # Server calling client (e.g. sampling?) - Not implemented yet
      when Protocol::Notification
        # Server notifications - Not implemented yet
      end
    end

    private def decode_typed(response : Protocol::Result | Protocol::Error, type : T.class) : T | Protocol::Error forall T
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
      else
        response
      end
    end
  end
end
