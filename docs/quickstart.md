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

## Typed Client API

```crystal
transport = Mcp::Transport::Stdio.new
client = Mcp::Client.new(transport)
client.start

init = client.connect_typed("my-app", "0.1.0")
list = client.list_tools_typed
```

## Other Capabilities

- Resources: `client.list_resources_typed`, `client.read_resource_typed`
- Prompts: `client.list_prompts_typed`, `client.get_prompt_typed`
- Logging: `client.set_log_level`, `client.on_logging_message`
- Roots (host-side): `client.add_root`, `client.on_roots_list`

## Other Transports

See `docs/transports.md`.

Key ideas:

- `class MyServer < Mcp::Server`
- Register tools with `tool("name", "desc", ...) do |args| ... end`
- Use `Mcp::Transport::Stdio` to exchange line-delimited JSON-RPC over STDIN/STDOUT
