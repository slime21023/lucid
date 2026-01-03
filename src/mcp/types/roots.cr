require "json"

module Mcp
  module Types
    # Root metadata returned from `roots/list`.
    struct Root
      include JSON::Serializable
      property uri : String
      property name : String?

      def initialize(@uri : String, @name : String? = nil)
      end
    end

    # `roots/list` success result payload.
    struct RootsListResult
      include JSON::Serializable
      property roots : Array(Root)

      def initialize(@roots : Array(Root))
      end
    end
  end
end

