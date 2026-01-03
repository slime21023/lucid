# Architecture Overview

## Modules

- `Mcp::Protocol`: JSON-RPC message types + parsing helpers
- `Mcp::Transport`: transports and framing (line-delimited JSON + WebSocket messages)
- `Mcp::Server`:
  - `Server::Router`: routes methods to handlers
  - `Server::Handlers::*`: capability modules (Lifecycle/Tools/Resources/Prompts/Logging)
  - `ServerDSL`: tools macro, registry, schema builder
- `Mcp::Client`: request/response correlation and typed decoding helpers (and host-side `roots/list` + `logging/message`)
- `Mcp::Types`: typed MCP payloads (initialize/tools/resources/prompts/logging/roots)

## Current Limitations

- Tool call results are currently modeled as text content only (`Mcp::Types::ToolCallResult` + `TextContent`).
- Transport framing is currently line-delimited JSON; header-based framing can be added under `Transport::Framing`.
