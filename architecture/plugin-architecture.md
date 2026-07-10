# Plugin Architecture

The single reference for how Unitill plugins work end-to-end. Decisions behind
it: [ADR-0001](../adr/0001-plugin-runtime-wasm.md) (runtimes),
[ADR-0002](../adr/0002-plugin-type-taxonomy.md) (types),
[ADR-0006](../adr/0006-plugin-trust-chain.md) (trust chain).

## 1. What a plugin is

A signed `tar.gz` bundle with a `manifest.json` at its root. The manifest
declares identity (`id`, `version`), a `canonical_type`, a `runtime`,
`permissions`, and `entries` — the concrete surfaces the plugin adds to the
till. Contract details: [reference/plugin-manifest.md](../reference/plugin-manifest.md).

## 2. Runtimes (ADR-0001)

| `runtime` | Executes | Use for |
|-----------|----------|---------|
| `none` | nothing — assets only | themes, language packs, content pages |
| `wasm` | in-process WASM module (wazero) — **live**, see [wasm-runtime.md](wasm-runtime.md) | payment glue, pricing, tax, schedulers, integrations, background jobs |
| `go` | separate supervised process | hardware/device drivers needing raw OS access (reserved; engine support pending) |

WASM modules are architecture-independent (one artifact for every till),
sandboxed by construction, and get host capabilities only per granted
permission. Disable = drop the instance.

## 3. Types and what the engine does with each (ADR-0002)

20 canonical types (see the taxonomy table in the manifest reference).
Engine support today:

- **Rendered natively:** `page` (menu entry → localized content bundle or
  static HTML), `button` (products panel, press → event), `theme`
  (CSS layered over the token-based base stylesheet; can reposition the
  sale-screen grid areas).
- **Integrated:** `payment` — entries sync into `payment_methods`
  (install/enable activate, disable/uninstall deactivate; rows never deleted
  because sales history references them). Active methods render on the Pay
  tab; completing a sale with one publishes the entry's `trigger_event` with
  `sale_id/amount/reference`.
- **Registered, engine pending:** the remaining types are validated, stored,
  and shown on the plugin info card; their engines land with the WASM runtime
  (popup, background_job, scheduler, notification, …) or the process runtime
  (device, hardware).

## 4. Trust chain (ADR-0006)

vendor upload → structural scan → review → approve+sign (Ed25519 over the
canonical manifest; POS pins the marketplace public key) → catalog →
merchant approval / self-serve entitlement (free listings) → download token →
checksum + signature verification on the till → install. Revoking an
entitlement blocks re-acquire. **The POS never runs an unverified bundle.**

## 5. Lifecycle on the till

- **Store** (`/plugins/store`): entitled listings; download (staged),
  install (verified), delete download.
- **Manager** (`/plugins`): enable/disable, update (goes through the same
  verified installer via the listing mapping), export (offline bundle),
  uninstall (files + rows removed; nav/methods resync), import
  (side-load `.tar.gz` — stays untrusted-tier, permissions not auto-granted).
- Every lifecycle change funnels through `Manager.Reload`, which rebuilds
  menu entries and re-syncs derived state (payment methods).

## 6. Events & permissions

`EventBus` (internal/plugins/ipc.go) publishes typed events
(`sale.completed`, per-plugin `trigger_event`s). Subscribers need the
`events:receive` permission; every publish/dispatch is written to the audit
log. Marketplace installs grant the permissions the signed manifest declares;
manual imports don't.

## 7. Distribution

One repo per plugin, named **`ut-plugin-{type}-{name}`** (ADR-0009), released by tagging `v<version>`:
CI validates → packages → uploads to the marketplace → (dev convenience)
auto-approves when `AUTO_APPROVE=true`. See the theme repos as the template.

## 8. Known gaps (tracked)

- `runtime:"go"` process supervision not implemented (hardware plugins).
- ut-plugin-faq still declares `runtime:"go"` + unused binary — convert to `none`.
- Merchant entitlement endpoints are unauthenticated (dev convenience).
