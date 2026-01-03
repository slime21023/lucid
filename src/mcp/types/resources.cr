require "json"

module Mcp
  module Types
    # Resource metadata returned from `resources/list`.
    struct Resource
      include JSON::Serializable

      property uri : String
      property name : String?
      property description : String?

      @[JSON::Field(key: "mimeType")]
      property mime_type : String?

      def initialize(@uri : String, @name : String? = nil, @description : String? = nil, @mime_type : String? = nil)
      end
    end

    # `resources/list` success result payload.
    struct ResourcesListResult
      include JSON::Serializable
      property resources : Array(Resource)

      def initialize(@resources : Array(Resource))
      end
    end

    # `resources/read` request params payload.
    struct ResourcesReadParams
      include JSON::Serializable
      property uri : String

      def initialize(@uri : String)
      end
    end

    # A single resource content item returned from `resources/read`.
    struct ResourceContent
      include JSON::Serializable

      property uri : String

      @[JSON::Field(key: "mimeType")]
      property mime_type : String?

      # Text content. (Binary blobs can be added later if needed.)
      property text : String?

      def initialize(@uri : String, @mime_type : String? = nil, @text : String? = nil)
      end
    end

    # `resources/read` success result payload.
    struct ResourcesReadResult
      include JSON::Serializable
      property contents : Array(ResourceContent)

      def initialize(@contents : Array(ResourceContent))
      end
    end
  end
end

