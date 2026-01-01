# Server (Tools)

## Overview

`Mcp::Server` receives `Mcp::Protocol::Message` values via a `Mcp::Transport::Base` implementation and dispatches requests/notifications via the server router/handlers.

Currently supported core methods:

- `initialize`
- `tools/list`
- `tools/call`

Canonical method names are defined in `Mcp::Protocol::Methods`.

## Defining Tools (DSL)

Register tools inside a server subclass:

```crystal
class MyServer < Mcp::Server
  tool("add", "Adds two numbers", a: Int32, b: Int32) do |args|
    args.a + args.b
  end
end
```

What the DSL does:

- Generates an args struct and decodes it from `arguments`
- Generates a minimal JSON Schema (`type/properties/required`) for `tools/list`

## Tool Handler Return Values

The tool block result is converted to JSON:

- If it is a `String`, `tools/call` returns that string directly as `content[0].text`.
- Otherwise, the value is JSON-encoded and returned as a string in `content[0].text`.

## Error Handling

- Unknown request method: `METHOD_NOT_FOUND`
- `tools/call` missing params: `INVALID_PARAMS`
- Unknown tool name: `METHOD_NOT_FOUND`
- Tool handler exception: `INTERNAL_ERROR`
