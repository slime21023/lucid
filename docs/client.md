# Client

## Create and Start

```crystal
require "lucid"

transport = Mcp::Transport::Stdio.new
client = Mcp::Client.new(transport)
client.start
```

## Transports

Lucid includes multiple transports. See `docs/transports.md`.

## Initialize Handshake

```crystal
res = client.connect("my-app", "0.1.0")
```

`connect` will:

- Send an `initialize` request
- Then send a `notifications/initialized` notification

## Tools

```crystal
tools_res = client.list_tools
call_res  = client.call_tool("add", {a: 1, b: 2})
```

Return type: `Mcp::Protocol::Result | Mcp::Protocol::Error`.

## Typed API (Recommended)

Typed helpers decode `Result#result` into `Mcp::Types::*`:

```crystal
init = client.connect_typed("my-app", "0.1.0")
list = client.list_tools_typed
call = client.call_tool_typed("add", {a: 1, b: 2})
```

If decoding fails, the helper returns `Mcp::Protocol::Error` (`INTERNAL_ERROR`).

## Resources

```crystal
list = client.list_resources_typed
read = client.read_resource_typed("file://example.txt")
```

## Prompts

```crystal
list = client.list_prompts_typed
get  = client.get_prompt_typed("my-prompt", {topic: "x"})
```

## Logging

```crystal
client.set_log_level("debug")
client.on_logging_message { |msg| puts msg.message }
```

## Serving `roots/list` (Host Side)

If you are using `Mcp::Client` as the host side of an MCP connection:

```crystal
client.add_root("file:///repo", "repo")
client.on_roots_list { Mcp::Types::RootsListResult.new(roots: client.roots) }
```

If you don't set `on_roots_list`, the client responds using the `roots` array populated by `add_root`.
