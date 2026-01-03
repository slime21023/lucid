# Transports

Lucid transports are implementations of `Mcp::Transport::Base`. They are responsible for:

- Reading frames from an IO or socket
- Parsing each frame into a `Mcp::Protocol::Message`
- Writing outgoing messages

## Framing

- `Mcp::Transport::Stdio` and `Mcp::Transport::Tcp` use line-delimited JSON (one JSON-RPC message per line).
- `Mcp::Transport::WebSocket` treats each WebSocket text message as a full JSON-RPC message.

## Stdio

The stdio transport is the simplest way to run an MCP server (works well with CLI hosts).

```crystal
transport = Mcp::Transport::Stdio.new
server = MyServer.new(transport)
server.start
```

## TCP

TCP uses the same line-delimited framing as stdio.

Client side:

```crystal
transport = Mcp::Transport::Tcp.connect("127.0.0.1", 3333)
client = Mcp::Client.new(transport)
client.start
```

Server side (single connection):

```crystal
tcp_server = TCPServer.new("127.0.0.1", 3333)
transport = Mcp::Transport::Tcp.accept(tcp_server)
server = MyServer.new(transport)
server.start
```

## WebSocket

WebSocket is useful when you want message-based IO instead of line-delimited IO.

```crystal
transport = Mcp::Transport::WebSocket.connect(URI.parse("ws://127.0.0.1:3333/mcp"))
client = Mcp::Client.new(transport)
client.start
```

