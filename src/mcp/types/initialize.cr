require "json"

module Mcp
  module Types
    # Client metadata sent during initialize.
    struct ClientInfo
      include JSON::Serializable
      property name : String
      property version : String

      def initialize(@name : String, @version : String)
      end
    end

    # Server metadata returned from initialize.
    struct ServerInfo
      include JSON::Serializable
      property name : String
      property version : String

      def initialize(@name : String, @version : String)
      end
    end

    # MCP tools capability flags.
    struct ToolsCapabilities
      include JSON::Serializable
      @[JSON::Field(key: "listChanged")]
      property list_changed : Bool?

      def initialize(@list_changed : Bool? = nil)
      end
    end

    # MCP resources capability flags.
    struct ResourcesCapabilities
      include JSON::Serializable
      @[JSON::Field(key: "listChanged")]
      property list_changed : Bool?

      def initialize(@list_changed : Bool? = nil)
      end
    end

    # MCP prompts capability flags.
    struct PromptsCapabilities
      include JSON::Serializable
      @[JSON::Field(key: "listChanged")]
      property list_changed : Bool?

      def initialize(@list_changed : Bool? = nil)
      end
    end

    # MCP logging capability flags.
    struct LoggingCapabilities
      include JSON::Serializable
      def initialize
      end
    end

    # MCP roots capability flags.
    struct RootsCapabilities
      include JSON::Serializable
      @[JSON::Field(key: "listChanged")]
      property list_changed : Bool?

      def initialize(@list_changed : Bool? = nil)
      end
    end

    # MCP capabilities container used by initialize.
    struct Capabilities
      include JSON::Serializable
      property tools : ToolsCapabilities?
      property resources : ResourcesCapabilities?
      property prompts : PromptsCapabilities?
      property logging : LoggingCapabilities?
      property roots : RootsCapabilities?

      def initialize(
        @tools : ToolsCapabilities? = nil,
        @resources : ResourcesCapabilities? = nil,
        @prompts : PromptsCapabilities? = nil,
        @logging : LoggingCapabilities? = nil,
        @roots : RootsCapabilities? = nil
      )
      end
    end

    # `initialize` request params payload.
    struct InitializeParams
      include JSON::Serializable
      @[JSON::Field(key: "protocolVersion")]
      property protocol_version : String
      property capabilities : Capabilities
      @[JSON::Field(key: "clientInfo")]
      property client_info : ClientInfo

      def initialize(@protocol_version : String, @capabilities : Capabilities, @client_info : ClientInfo)
      end
    end

    # `initialize` success result payload (inside `Mcp::Protocol::Result#result`).
    struct InitializeResult
      include JSON::Serializable
      @[JSON::Field(key: "protocolVersion")]
      property protocol_version : String
      property capabilities : Capabilities
      @[JSON::Field(key: "serverInfo")]
      property server_info : ServerInfo

      def initialize(@protocol_version : String, @capabilities : Capabilities, @server_info : ServerInfo)
      end
    end
  end
end
