# Review — payment authorization gate + stale-module fix (P1.1b engine step)

Date: 2026-07-14 · Repos: universal-till 835126d, ut-plugin-payment-demo
v1.1.0 · Spec: `architecture/wasm-runtime.md` § payment authorization.

## What shipped

- **Blocking pre-tender authorization**: plugin payment methods whose
  plugin hooks `payment.<key>.authorize` get a synchronous call **before**
  `CompleteSale`. Handler error (or deadline) → **402, no sale row,
  basket intact** — a declined card finally stops the sale. Approval →
  sale completes and the existing post-settle `payment.<key>.requested`
  fires as before. No subscriber = old behaviour (qrpay untouched).
  `EventBus.HasSubscribers` added; `.authorize` hook events are set to
  Blocking mode at wasm Sync (the mode the bus had reserved in comments
  since day one).
- **Demo plugin v1.1.0**: authorize hook carries the verdict (.13 exits 2
  → declined; .99 sleeps → deadline path; else approves with auth code);
  `payment.demo.requested` now files the settled txn under the sale id.
  Released through the normal pipeline (green), updated on the till via
  the verified updater.

## Bugs found live (both fixed)

1. **Stale compiled module on plugin update**: `WasmRuntime.load`
   early-returned whenever a module was already compiled for the plugin
   id — after the 1.0.0→1.1.0 update the till kept executing 1.0.0 code
   until restart (caught because plugin-storage rows carried the old
   code's shape). Now recompiles when the installed version changes,
   closing the old module; version map cleaned on unload.
2. Stray dev backup file committed from the repo-dir server run —
   removed, `data/backups/` ignored.

## Notes

- The `.99` "timeout" card returns immediately rather than after the 2s
  deadline: wazero's default config makes `time.Sleep` a no-op (no
  nanosleep). The outcome path (error → 402 → no sale) is identical, so
  the simulation is behaviourally right; enabling real sleep
  (`WithNanosleep`) is noted for when a plugin legitimately needs it.
- Authorization runs inside the tender request, bounded by the module
  deadline (2s / 10s with net:) — payments are the one flow that is
  *supposed* to wait; printing etc. stay async.

## Verification

Full suite + guards green. Live E2E on the marketplace-installed plugin
(after the stale-module fix, confirmed by the new code's log format):
decline `.13` → 402 "payment declined: demo_card", **sales count
unchanged**; approve `.50` → 200, sale created, `APPROVED … DEMO-000250`
and post-settle `settled sale <id>` in the log, txn rows in plugin
storage.
