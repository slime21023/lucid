# Server

## Overview

`Mcp::Server` receives `Mcp::Protocol::Message` values via a `Mcp::Transport::Base` implementation and dispatches requests/notifications via the server router/handlers.

Currently supported core methods:

- `initialize`
- `tools/list`
- `tools/call`
- `resources/list`
- `resources/read`
- `prompts/list`
- `prompts/get`
- `logging/setLevel`

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

## Defining Resources

Register resources on a server instance (typically in `initialize`):

```crystal
class MyServer < Mcp::Server
  def initialize(transport : Mcp::Transport::Base)
    super(transport)

    resources.register(
      "file://example.txt",
      name: "example",
      description: "An example resource",
      mime_type: "text/plain"
    ) do
      "Hello"
    end
  end
end
```

The handler must return a `String` which becomes the `text` field in `resources/read`.

## Defining Prompts

Register prompts on a server instance:

```crystal
class MyServer < Mcp::Server
  def initialize(transport : Mcp::Transport::Base)
    super(transport)

    prompts.register(
      "greet",
      description: "Greets the user",
      arguments: [Mcp::Types::PromptArgument.new(name: "name", required: true)]
    ) do |args|
      name = args.try &.[]?("name").try &.as_s? || "world"
      Mcp::Types::PromptsGetResult.new(
        messages: [Mcp::Types::PromptMessage.new(role: "user", content: "Hello, #{name}!")]
      )
    end
  end
end
```

## Logging

The server can emit logs to the host via `logging/message` notifications:

```crystal
server.log_info("Started", "my-server")
server.log_error("Something failed")
```

## Tool Handler Return Values

The tool block result is converted to JSON:

- If it is a `String`, `tools/call` returns that string directly as `content[0].text`.
- Otherwise, the value is JSON-encoded and returned as a string in `content[0].text`.

## Error Handling

- Unknown request method: `METHOD_NOT_FOUND`
- `tools/call` missing params: `INVALID_PARAMS`
- Unknown tool name: `METHOD_NOT_FOUND`
- Tool handler exception: `INTERNAL_ERROR`

## Host Capabilities (Roots)

`roots/list` is a host (client) capability. Servers can request it with:

```crystal
roots = server.list_roots_typed
```
