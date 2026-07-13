# Review: ut-plugin-button-nosale — reference sample for the `button` type (2026-07-13)

New repo `universaltill/ut-plugin-button-nosale` v1.0.0 (initial commit
`b0c4bbe`), continuing the sample-plugin-per-type task. Scaffold mirrors
`ut-plugin-payment-qrpay` (the most recent wasm sample), adapted for
`canonical_type:"button"`.

## What it is

A classic **No Sale** till button. The manifest registers one `button` entry
(`key:no-sale`, `trigger_event:button.nosale.pressed`) plus a wasm hook on
the same event, so the sample demonstrates the whole button loop: sale-screen
render → press → EventBus publish → in-process WASI handler → audited result.
The handler records a `drawer.open` / `reason:no_sale` request on the audit
trail; driving a physical drawer is explicitly left to a future
hardware/device plugin subscribed to the same event.

## Review notes (self-review against the qrpay template)

- `scripts/validate.sh` rewritten for the button contract: exactly one
  `type:"button"` entry with key/label/trigger_event; runtime none|wasm
  (ADR-0001); `device_arch:any`; wasm entrypoint must exist.
- `scripts/publish.sh` carried a stale `release_notes=Theme release …` string
  from the theme lineage — fixed to a neutral `Release <version>` (cosmetic;
  qrpay still has it).
- Unlike qrpay, `dist/` and `bin/` are **gitignored** — CI builds the module
  fresh every run, so tracking build outputs only bloats history.
- Event payload struct in `src/main.go` matches what the POS actually
  publishes for button presses (`plugin_id`/`entry_key`/`label`,
  plugin_page.go action handler), verified against source before writing.

## Verified live (full path, dev marketplace + local POS)

- Release pipeline green on tag v1.0.0: HTTP 201 upload → auto-approve →
  `release_status=approved`. Listing `9efa479a-9cdf-4466-951f-ff901ed2f1db`
  (repo var `MARKETPLACE_LISTING_ID` set; secrets from KV as usual).
- Catalog serves `No Sale 1.0.0 type=button`.
- POS one-click install: “Manifest signature verified”, wasm module loaded
  handling `button.nosale.pressed`.
- `/ui/plugin-buttons` renders the button; POST action → audit rows
  `event_published subscribers=1` + `event_dispatch enqueued`; wasm handler
  logged the drawer-release request and returned
  `{"handled":true,"action":"drawer.open","reason":"no_sale",…}`.
- Disable hides the button from the partial; enable restores it.

## Follow-ups

- Samples still missing for engine-less types (popup, background_job,
  scheduler, …) — add as engines land.
- ut-plugin-faq remains `runtime:"go"` legacy (existing tracked gap).
