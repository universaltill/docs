# Code review — in-process WASM plugin runtime (universal-till + ut-plugin-payment-qrpay)

**Date:** 2026-07-11 · Spec: architecture/wasm-runtime.md (ADR-0001, document-first)

## What shipped
`internal/plugins/wasm_runtime.go` (wazero): compile-once/instantiate-per-event
WASI command model; event JSON on stdin; stdout audited to log, stderr to POS
log; 2s deadline; no fs/network. `Manager.Init/Reload → Wasm.Sync` loads active
runtime:"wasm" plugins and subscribes each to its **manifest hooks**
(plugin_hooks) — entries' trigger_event = what the POS publishes, hooks = what
the plugin consumes. Dispatch stays permission-gated (events:receive) + audited.

## Real engine bugs found & fixed en route
1. **Publishers each constructed their own EventBus** → in-memory subscribers
   could never receive anything (the eternal `subscribers=0`). `SharedBus` now.
2. **Non-blocking dispatch never invoked handlers** (only enqueued to a channel
   nobody drained) — runtime drains its subscription channel.
3. **ResetSubscribers leaked drainer goroutines** — now closes channels.
4. Installer/verifier: wasm modules verified for existence (no +x bit);
   `entrypoint` accepted where legacy `executable` was demanded.

## Proven live (marketplace path, not side-load)
ut-plugin-payment-qrpay v1.1.1: plain Go (`GOOS=wasip1 GOARCH=wasm`), pipeline
built+published+approved → POS update (signature verified) → sale tendered via
QR Pay → module executed in-process: logged "settling sale … 252 minor units",
returned `{"handled":true,"qr":"unitill://pay?...&amount=252"}`; audit
`subscribers=1`. Full test suite + guard green.

## Follow-ups
Host functions (storage/HTTP by permission), resident reactor modules
(go:wasmexport), popup/background_job/scheduler engines on this base.
