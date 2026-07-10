# 0001 — Plugin runtime: in-process WASM; separate processes only for hardware

**Status:** accepted (2026-07-10, Farshid)

## Context
Plugins need to execute logic (payment glue, pricing, tax, schedulers,
integrations). The till runs on Pi-class hardware: separate processes cost
10–50 MB RSS each plus IPC, supervision and per-architecture builds. Go's
`plugin` package is too brittle (exact toolchain match, no unload).

## Decision
- `runtime: "wasm"` is the canonical runtime for logic plugins, executed
  **in-process** by the POS via **wazero** (pure-Go, no cgo). One
  architecture-independent `.wasm` artifact per plugin; authors may write Go
  (`GOOS=wasip1 GOARCH=wasm`), Rust, TinyGo, etc.
- Capabilities are granted explicitly by the host; a module gets nothing by
  default (aligns with the manifest permission model + Ed25519 signing).
  Calls run under deadlines; disable = drop the module instance.
- `runtime: "none"` stays for asset-only plugins (themes, language packs).
- `runtime: "go"` (separate supervised process) is **reserved for hardware /
  device plugins** that need raw OS access (USB/serial); minority case.

## Consequences
Multi-arch publishing pain disappears for logic plugins. The engine gains a
wazero dependency and a host-function API surface (events, storage, HTTP by
permission). Existing `runtime:"go"` manifests (ut-plugin-faq) are legacy —
convert to `none` (content-only) or `wasm`.
