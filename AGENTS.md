# Repository Guidelines

## Project Structure & Module Organization

- `src/` contains the library code.
  - `src/lucid.cr` is the shard entrypoint (`require "lucid"`).
  - `src/mcp.cr` is the main SDK entrypoint (`Mcp` namespace).
  - `src/mcp/` holds implementation modules:
    - `protocol/` JSON-RPC types + parsing helpers
    - `transport/` transports and framing
    - `server/` server router/handlers + tool DSL
    - `types/` typed MCP payloads (`Mcp::Types::*`)
- `spec/` contains tests (Crystal Spec) and `spec/runner.cr` for coverage runs.
- `examples/` contains runnable examples (e.g. `examples/math_server.cr`).

Prefer extending existing modules under `src/mcp/**` and keep public API additions under the `Mcp` namespace.

## Build, Test, and Development Commands

- `crystal spec` — runs the test suite.
- `crystal run examples/math_server.cr` — runs an example MCP server over stdio.
- `crystal build src/lucid.cr` — compiles the shard entrypoint to validate compilation.
- `crystal tool format src spec` — formats touched code.

## Coverage Reporting

Coverage is generated via Crystal's built-in reachability analysis (`crystal tool unreachable`):

- `bash scripts/coverage.sh` — writes `coverage/coverage.json`, `coverage/unreachable.csv`, and `coverage/summary.txt`.
- On Windows: `powershell -File scripts/coverage.ps1`.
- GitHub Actions generates and uploads `coverage/` as a workflow artifact (`.github/workflows/ci.yml`).

## Coding Style & Naming Conventions

- Crystal standard style: 2-space indentation, no tabs.
- Filenames: `snake_case.cr`; types/modules: `CamelCase`; methods/vars: `snake_case`.
- Keep API names stable once exposed; prefer small, focused PRs.

## Testing Guidelines

- Framework: Crystal Spec (`spec/`).
- Naming: `*_spec.cr` with `describe` blocks per type/module.
- Add specs for both success and error paths (parsing, routing, tool execution, typed decoding).

## Commit & Pull Request Guidelines

This checkout does not include git history, so no established convention can be inferred. Recommended:

- Use Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `test:`).
- PRs should include: motivation, what changed, how to verify (`crystal spec`), and an example/spec update when adding features.
