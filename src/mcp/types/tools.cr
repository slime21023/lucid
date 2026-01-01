require "json"

module Mcp
  module Types
    # Tool metadata returned from `tools/list`.
    struct Tool
      include JSON::Serializable
      property name : String
      property description : String
      @[JSON::Field(key: "inputSchema")]
      property input_schema : JSON::Any

      def initialize(@name : String, @description : String, @input_schema : JSON::Any)
      end
    end

    # `tools/list` success result payload.
    struct ToolsListResult
      include JSON::Serializable
      property tools : Array(Tool)

      def initialize(@tools : Array(Tool))
      end
    end

    # `tools/call` request params payload.
    struct ToolsCallParams
      include JSON::Serializable
      property name : String
      property arguments : JSON::Any?

      def initialize(@name : String, @arguments : JSON::Any? = nil)
      end
    end
  end
end
