require "json"

module Mcp
  module Types
    # Text content item used in tool call results.
    struct TextContent
      include JSON::Serializable
      property type : String = "text"
      property text : String

      def initialize(@text : String, @type : String = "text")
      end
    end

    # `tools/call` success result payload (currently text-only).
    struct ToolCallResult
      include JSON::Serializable
      property content : Array(TextContent)

      def initialize(@content : Array(TextContent))
      end
    end
  end
end
