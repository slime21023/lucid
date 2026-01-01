# Quick Start

## Install & Require

```crystal
require "lucid"
```

The primary API lives under the `Mcp` namespace.

## Run a Tools Server (stdio)

See the example: `examples/math_server.cr`

```bash
crystal run examples/math_server.cr
```

Key ideas:

- `class MyServer < Mcp::Server`
- Register tools with `tool("name", "desc", ...) do |args| ... end`
- Use `Mcp::Transport::Stdio` to exchange line-delimited JSON-RPC over STDIN/STDOUT
