# Client

## Create and Start

```crystal
require "lucid"

transport = Mcp::Transport::Stdio.new
client = Mcp::Client.new(transport)
client.start
```

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
