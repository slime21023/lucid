require "json"

module Mcp
  module Protocol
    # JSON-RPC 2.0 message types used by MCP.
    abstract class Message
      include JSON::Serializable
      
      property jsonrpc : String = "2.0"
    end

    # JSON-RPC Request (has `id`).
    class Request < Message
      property method : String
      property params : JSON::Any?
      property id : (String | Int64 | Nil)

      def initialize(@method : String, @params : JSON::Any? = nil, @id : (String | Int64 | Nil) = nil)
      end
    end

    # JSON-RPC Notification (no `id`).
    class Notification < Message
      property method : String
      property params : JSON::Any?

      def initialize(@method : String, @params : JSON::Any? = nil)
      end
    end

    # JSON-RPC Success response.
    class Result < Message
      property result : JSON::Any
      property id : (String | Int64)

      def initialize(@result : JSON::Any, @id : (String | Int64))
      end
    end

    # JSON-RPC Error response.
    class Error < Message
      class ErrorData
        include JSON::Serializable
        property code : Int32
        property message : String
        property data : JSON::Any?

        def initialize(@code : Int32, @message : String, @data : JSON::Any? = nil)
        end
      end

      property error : ErrorData
      property id : (String | Int64 | Nil)

      def initialize(@error : ErrorData, @id : (String | Int64 | Nil) = nil)
      end
      
      # predefined error codes
      PARSE_ERROR = -32700
      INVALID_REQUEST = -32600
      METHOD_NOT_FOUND = -32601
      INVALID_PARAMS = -32602
      INTERNAL_ERROR = -32603
    end
    
    # Union type for parsing generic messages
    # This helps when we first read a message and don't know if it's a request/response yet.
    # However, JSON::Serializable union parsing can be tricky.
    # For now, we often parse as JSON::Any and then map to specific types, or use a discriminator.
  end
end
