module Mcp
  module Protocol
    # Canonical MCP method names.
    module Methods
      INITIALIZE                = "initialize"
      NOTIFICATIONS_INITIALIZED = "notifications/initialized"
      TOOLS_LIST                = "tools/list"
      TOOLS_CALL                = "tools/call"

      RESOURCES_LIST = "resources/list"
      RESOURCES_READ = "resources/read"

      PROMPTS_LIST = "prompts/list"
      PROMPTS_GET  = "prompts/get"

      LOGGING_SET_LEVEL = "logging/setLevel"
      LOGGING_MESSAGE   = "logging/message"

      ROOTS_LIST = "roots/list"
    end
  end
end
