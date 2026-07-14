# Review — WASM host functions v2 (storage + permission-gated HTTP)

Date: 2026-07-14 · Repo: universal-till · Spec: `architecture/wasm-runtime.md`
§ "Host functions — v2" (written first, ADR-0007). This is the enabler for
Farshid's 2026-07-14 direction: **AI/Ollama as an opt-in marketplace plugin**
(`ut-plugin-integration-ai`) — a plugin can now hold `net:<ollama-host>` and
talk to a self-hosted model server, on the till or a separate machine.

## What shipped

- Host module **`ut`** registered on the wazero runtime: `log_write`,
  `storage_get`, `storage_set`, `http_request`. Buffer ABI: host writes
  `min(len, cap)`, returns full length (guest retries bigger); negative
  codes -1 not-found / -2 denied / -3 internal / -4 invalid.
- **Per-call permission gating** through the existing `CheckPermission`
  (denials audited, grants revocable live, no module reload needed):
  `storage` for KV, `net:<hostname>` per exact host for HTTP.
- **Storage**: migration 011 `plugin_storage` (namespaced KV), repo methods
  with caps (key 128 B, value 64 KiB, 1024 keys/plugin). Cleared on
  uninstall (no FK — explicit `DeleteStorage`).
- **HTTP**: JSON request/response with base64 bodies, response cap 256 KiB,
  HTTPS-only except plain http to loopback (self-hosted Ollama), per-plugin
  User-Agent, runs under the module deadline. Plugins holding any granted
  `net:` permission get a 10s event deadline instead of 2s (computed at
  Sync).
- Caller identity reaches host functions via the per-instantiation context
  (`hostState{pluginID, db}`) — one host-module registration serves all
  plugins in parallel with no shared mutable state.
- Author docs: `reference/plugin-host-functions.md` (permissions, ABI,
  copy-paste Go bindings, HTTP shapes).

## Security notes

- A plugin can only reach hosts it declared at install (merchant sees the
  list) AND that were granted; scheme restrictions block downgrade to
  plain http off-box. No filesystem/clock/env access was added.
- Storage is namespaced by plugin id server-side; a plugin cannot name
  another plugin's namespace.

## Verification

- Tests build a real wasip1 guest (`testdata/hostfn_guest`, plain Go
  `//go:wasmimport`) and run it through the actual runtime:
  storage round-trip via host functions; HTTP GET to an httptest server
  (status+body+User-Agent asserted); **denial without `net:` permission —
  the request provably never reaches the server**; storage denied without
  the `storage` permission (no rows written). Full `go test ./...` +
  data-access and i18n guards green.
- Live-path proof deferred to the first consumer plugin
  (ut-plugin-integration-ai) — the runtime path (Sync → subscribe →
  HandleEvent) is unchanged from the proven qrpay flow.
