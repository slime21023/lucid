# Lucid shard entrypoint.
#
# `require "lucid"` loads the `Mcp` namespace (the MCP SDK) and also exposes
# `Lucid::VERSION` for shard/version metadata.
module Lucid
  VERSION = "0.1.0"
end

require "./mcp"
