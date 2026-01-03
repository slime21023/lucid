require "json"

module Mcp
  module Types
    # Prompt argument metadata.
    struct PromptArgument
      include JSON::Serializable
      property name : String
      property description : String?
      property required : Bool?

      def initialize(@name : String, @description : String? = nil, @required : Bool? = nil)
      end
    end

    # Prompt metadata returned from `prompts/list`.
    struct Prompt
      include JSON::Serializable
      property name : String
      property description : String?
      property arguments : Array(PromptArgument)?

      def initialize(@name : String, @description : String? = nil, @arguments : Array(PromptArgument)? = nil)
      end
    end

    # `prompts/list` success result payload.
    struct PromptsListResult
      include JSON::Serializable
      property prompts : Array(Prompt)

      def initialize(@prompts : Array(Prompt))
      end
    end

    # `prompts/get` request params payload.
    struct PromptsGetParams
      include JSON::Serializable
      property name : String
      property arguments : JSON::Any?

      def initialize(@name : String, @arguments : JSON::Any? = nil)
      end
    end

    # A prompt message returned from `prompts/get`.
    struct PromptMessage
      include JSON::Serializable
      property role : String
      property content : String

      def initialize(@role : String, @content : String)
      end
    end

    # `prompts/get` success result payload.
    struct PromptsGetResult
      include JSON::Serializable
      property description : String?
      property messages : Array(PromptMessage)

      def initialize(@messages : Array(PromptMessage), @description : String? = nil)
      end
    end
  end
end

