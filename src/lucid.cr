# Lucid shard entrypoint.
#
# `require "lucid"` loads the `Mcp` namespace (the MCP SDK) and also exposes
# `Lucid::VERSION` for shard/version metadata.
require "./mcp"

module Lucid
  VERSION = Mcp::VERSION
end
