require "json"

module Mcp
  module Types
    # `logging/setLevel` request params payload.
    struct LoggingSetLevelParams
      include JSON::Serializable
      property level : String

      def initialize(@level : String)
      end
    end

    # `logging/message` notification params payload.
    struct LoggingMessageParams
      include JSON::Serializable
      property level : String
      property message : String
      property logger : String?

      def initialize(@level : String, @message : String, @logger : String? = nil)
      end
    end
  end
end

