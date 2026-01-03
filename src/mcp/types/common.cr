require "json"

module Mcp
  module Types
    # Represents an empty JSON object result (`{}`).
    #
    # Some MCP methods return no payload on success; this type provides a stable
    # typed target for `*_typed` helpers.
    struct EmptyResult
      include JSON::Serializable

      def initialize
      end
    end
  end
end
