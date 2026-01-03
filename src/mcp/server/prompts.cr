require "../types/prompts"

module Mcp
  class Server
    struct PromptDefinition
      getter prompt : Types::Prompt
      getter handler : Proc(JSON::Any?, Types::PromptsGetResult)

      def initialize(@prompt : Types::Prompt, @handler : Proc(JSON::Any?, Types::PromptsGetResult))
      end
    end

    class PromptRegistry
      def initialize
        @prompts = Hash(String, PromptDefinition).new
      end

      def register(name : String, description : String? = nil, arguments : Array(Types::PromptArgument)? = nil, &block : JSON::Any? -> Types::PromptsGetResult)
        prompt = Types::Prompt.new(name: name, description: description, arguments: arguments)
        @prompts[name] = PromptDefinition.new(prompt, block)
      end

      def []?(name : String)
        @prompts[name]?
      end

      def values
        @prompts.values
      end
    end
  end
end

