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

## Host functions — v2 (spec 2026-07-14)

Modules import host module **`ut`** (Go guests: `//go:wasmimport ut <name>`).
Every capability is **permission-gated per call** through the existing
`CheckPermission` path, so denials are audited and grants are revocable at
runtime without reloading the module.

| import | permission | semantics |
|---|---|---|
| `log_write(ptr,len)` | none | line into the POS log, prefixed `[wasm:<id>]` |
| `storage_get(kPtr,kLen,dstPtr,dstCap) i32` | `storage` | per-plugin KV read |
| `storage_set(kPtr,kLen,vPtr,vLen) i32` | `storage` | per-plugin KV write |
| `http_request(reqPtr,reqLen,dstPtr,dstCap) i32` | `net:<host>` | outbound HTTP |

- **Buffer ABI**: calls that return data write `min(len, dstCap)` bytes into
  the guest buffer and return the FULL length; if it exceeds `dstCap` the
  guest retries with a bigger buffer. Negative returns: `-1` not found,
  `-2` permission denied, `-3` internal error, `-4` invalid/too large.
- **Storage**: SQLite `plugin_storage` (migration 011), namespaced by plugin
  id. Caps: key ≤ 128 B, value ≤ 64 KiB, ≤ 1024 keys/plugin — a plugin
  cannot bloat a Pi's SD card.
- **HTTP**: request/response as JSON (`method,url,headers,body_b64` /
  `status,headers,body_b64`, response body ≤ 256 KiB). The URL's hostname
  must be covered by a granted `net:<host>` permission — the manifest
  declares exactly which hosts a plugin may talk to, shown at install.
  HTTPS only, except plain http to localhost (dev/Ollama). The call runs
  under the module's deadline; plugins holding any `net:` permission get a
  **10s** event deadline instead of the default 2s.
- State reaches host functions via the instantiation context (plugin id +
  db handle), so one host-module registration serves every plugin safely
  in parallel.
- This is the tool surface `ut-plugin-integration-ai` and device-onboarding
  plugins build on; reference + copy-paste Go guest bindings live in
  `reference/plugin-host-functions.md`.

## Payment authorization (2026-07-14)

A payment plugin can hook **`payment.<key>.authorize`** (alongside its
post-settle `payment.<key>.requested`). When any plugin subscribes, the
tender path publishes it **blocking, BEFORE `CompleteSale`**: module exit 0
= approved (sale proceeds), non-zero or deadline = declined (**402, no sale
row is created**, basket intact). `.authorize` hook events get Blocking
mode automatically at Sync. No subscriber = the old post-settle-only
behaviour (qrpay unchanged). Reference consumer:
`ut-plugin-payment-demo` v1.1.0 (deterministic fake cards). This is the
engine seam real terminal plugins (SumUp/Stripe Terminal) build on — they
additionally hold `net:<provider>` and get the 10s deadline.

Fixed along the way: `WasmRuntime.load` kept the previously compiled
module across plugin **updates** — the till executed stale code until
restart. Modules now recompile when the installed version changes.

## Out of scope (planned)
Resident reactor modules with `go:wasmexport`, popup/background_job/scheduler
engines on top of this, host-function quotas beyond the size caps.
