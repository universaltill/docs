# Review: remote design/theme picker (Universal Till Cloud 2b)

**Date:** 2026-07-19 · **Repos:** `universal-till` (feat/remote-theme),
`ut-market-place` (feat/remote-theme-picker)
**Queue item:** 2b "Remote settings & design/theme" — Farshid: "we should be
able to change the design" of a shop from the cloud.

## Design

The theme was already remotely changeable — it's the `theme` setting, and the
`set_setting` directive re-derives runtime state live. What was missing was
honesty about *choices*: themes are per-till (one built-in + plugin-contributed
entries), so a hardcoded cloud-side dropdown would lie. Instead the till now
reports its design state in the heartbeat and the cloud renders a picker from
what the shop actually has:

- **Till**: `cloudsync.Hooks` gains optional `DeviceExtra(ctx) map[string]any`,
  merged into the device report (fixed report fields win on key collision —
  tested). The pages wiring feeds it `theme` (current) + `themes`
  (`availableThemes()` keys+labels — same source as the local Settings page).
  Also this branch (earlier commit): first sync tick 90s→15s, interval 5m→2m,
  so a queued install/design change applies right after boot and within ~2 min
  on a running till.
- **Cloud**: `deviceReport` gains `theme` / `themes[{key,label}]`;
  `mergeDeviceState` folds them into `metadata.devices`. `claims.StoreDetail`
  gains `Theme` (primary till's report leads) + `Themes` (union across the
  fleet, deduped by key). `store_detail.html` shows a **Design** select +
  "Apply design" button above the raw key/value form — it posts the existing
  `/ui/api/merchant/stores/directives` endpoint with `type=set_setting`,
  `key=theme`, so queueing/cancel/history/idempotency all come for free. The
  picker only renders once a till has reported (`{{if .Store.Themes}}`), so
  old-fleet stores see no dead UI.

## Risk review

- No new endpoint, no new directive type, no new auth surface — the picker is
  sugar over the existing merchant-scoped `set_setting` queue.
- `DeviceExtra` collision guard keeps a buggy hook from overwriting
  `device_id`/`role`/etc. (covered by test with a malicious `role` key).
- Locale guard: `storedetail.design` / `storedetail.apply_design` added to all
  9 locale files (script-inserted next to `storedetail.remote_hint`).
- Old tills that don't report themes: `Themes` empty → no picker, generic form
  still there. Old cloud + new till: unknown JSON fields ignored. Both
  directions degrade cleanly.

## Tests

- till `TestTickPushesHeartbeatAndAppliesDirectives`: extras ride along,
  collision ignored. Full till suite + data-access guard green.
- mp `stores_sync_test`: theme + themes merged into `metadata.devices`.
- mp `scripts/ci/verify.sh` fully green (fmt, vet, golangci-lint, tests,
  contract guard).
