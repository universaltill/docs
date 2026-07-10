# WASM Plugin Runtime — v1 spec

Implements [ADR-0001](../adr/0001-plugin-runtime-wasm.md). Status: spec agreed
2026-07-11, implementation in universal-till `internal/plugins`.

## Goal
Run `runtime: "wasm"` plugin logic **in-process** on the till: sandboxed,
architecture-independent, cheap enough for Pi-class hardware. First consumer:
payment plugins reacting to their `trigger_event` (e.g. QR Pay).

## Execution model — WASI command, one instantiation per event
The plugin ships a `plugin.wasm` (WASI preview 1 "command": a `main()`), built
with plain Go: `GOOS=wasip1 GOASM=wasm go build`. The engine (wazero, pure Go):

1. **Compiles** the module once at load (plugin install/enable), caches it.
2. Per event: **instantiates** the compiled module (~ms), passing
   - stdin: the event as JSON `{ "id", "type", "timestamp", "payload": {...} }`
   - args: `plugin.wasm <event-type>`
   - stdout: captured; if non-empty it must be JSON (logged to the audit trail)
   - stderr: captured into the POS log, prefixed with the plugin id
3. A **deadline** (default 2s) cancels runaway modules; instance memory is
   discarded after each call — no state leaks between events.

No filesystem, network, or clock access in v1 — the module gets nothing but
stdin/stdout/stderr and args. Capabilities grow later per manifest permission.

## Event wiring
- One **shared** EventBus per process (`plugins.SharedBus`) — previously each
  publisher constructed its own bus, so in-memory subscribers could never fire.
- On `Manager.Reload`, the engine loads every active plugin with
  `runtime:"wasm"` and subscribes it (via `SubscribeWithHandler`) to the
  `trigger_event`s declared by its own entries.
- Dispatch stays permission-gated (`events:receive`) and audited per the
  existing EventBus rules; wasm handler results audit as success/error.

## Failure semantics
Compile or load failure marks the plugin errored in the log but never blocks
the till (offline-first: checkout must not depend on a plugin). Handler
errors/timeouts audit as `error` and are dropped — non-blocking mode.

## Out of scope for v1 (planned)
Host functions (storage, HTTP by permission), resident reactor modules with
`go:wasmexport`, popup/background_job/scheduler engines on top of this.
