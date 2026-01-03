# Lucid (Crystal MCP SDK)

`lucid` is a Model Context Protocol (MCP) SDK for Crystal, focused on an ergonomic API and fast server/client development.

## Install

Add to your `shard.yml`:

```yml
dependencies:
  lucid:
    github: https://github.com/slime21023/lucid
```

Then:

```crystal
require "lucid" # Provides the `Mcp` namespace
```

## Quick Start (Tools Server)

See `examples/math_server.cr`:

```bash
crystal run examples/math_server.cr
```

## Docs

See `docs/README.md`.

## Development

```bash
crystal spec
```

## Coverage

Coverage is generated via Crystal's built-in reachability analysis (`crystal tool unreachable`):

```bash
bash scripts/coverage.sh
```

Outputs are written to `coverage/` (JSON + CSV + summary). In CI, the report is uploaded as a workflow artifact.

On Windows, run:

```powershell
powershell -File scripts/coverage.ps1
```

## Current Features

- JSON-RPC message model: `Mcp::Protocol::*`
- Stdio transport: `Mcp::Transport::Stdio`
- Tools DSL: `Mcp::ServerDSL.tool` (auto input schema + handler)
- `Mcp::Client` (initialize / tools/list / tools/call) + typed helpers (`*_typed`)
- Typed MCP payloads: `Mcp::Types::*` (initialize/tools/tool result)

## Documentation

- API docs: `crystal docs` (generates docs from in-source doc comments)

## Roadmap

- [x] Resources / Prompts / Roots / Logging capabilities
- [x] Expand typed coverage (more capabilities)
- [x] More transports (TCP / WebSocket)
