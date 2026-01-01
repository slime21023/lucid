require "./mcp/protocol/**"
require "./mcp/transport/**"
require "./mcp/types/**"
require "./mcp/json_any"
require "./mcp/server"
require "./mcp/client"

# Crystal MCP SDK.
#
# Primary entrypoint for the SDK is the `Mcp` namespace. Most users should
# `require "lucid"` (which loads this file) and then use `Mcp::Server` and
# `Mcp::Client`.
module Mcp
  VERSION = Lucid::VERSION
end
