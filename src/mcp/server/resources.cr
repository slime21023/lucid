require "../types/resources"

module Mcp
  class Server
    struct ResourceDefinition
      getter resource : Types::Resource
      getter handler : Proc(String)

      def initialize(@resource : Types::Resource, @handler : Proc(String))
      end
    end

    class ResourceRegistry
      def initialize
        @resources = Hash(String, ResourceDefinition).new
      end

      def register(uri : String, name : String? = nil, description : String? = nil, mime_type : String? = nil, &block : -> String)
        resource = Types::Resource.new(uri: uri, name: name, description: description, mime_type: mime_type)
        @resources[uri] = ResourceDefinition.new(resource, block)
      end

      def []?(uri : String)
        @resources[uri]?
      end

      def values
        @resources.values
      end
    end
  end
end

