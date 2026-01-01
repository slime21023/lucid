# Architecture Overview

## Modules

- `Mcp::Protocol`: JSON-RPC message types + parsing helpers
- `Mcp::Transport`: transports and framing (currently line-delimited JSON)
- `Mcp::Server`:
  - `Server::Router`: routes methods to handlers
  - `Server::Handlers::*`: capability modules (Lifecycle/Tools)
  - `ServerDSL`: tools macro, registry, schema builder
- `Mcp::Client`: request/response correlation and typed decoding helpers
- `Mcp::Types`: typed MCP payloads (initialize/tools/tool result)

## Current Limitations

- Tool call results are currently modeled as text content only (`Mcp::Types::ToolCallResult` + `TextContent`).
- Transport framing is currently line-delimited JSON; header-based framing can be added under `Transport::Framing`.
