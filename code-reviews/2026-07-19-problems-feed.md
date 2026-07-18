# Review: per-shop Problems & logs feed (Universal Till Cloud 2a)

**Date:** 2026-07-19 · **Repos:** `universal-till` (feat/problems-digest),
`ut-market-place` (feat/problems-feed)
**Queue item:** 2a "Problems & logs surface" — Farshid's ADR-0018 ask: "see the
problems and logs etc of the shops, till devices and backoffice device".

## Design

A **digest, not a log shipper** — deliberately small so it stays off the sale
path and cheap on the 2-minute heartbeat:

- **Till**: `internal/logging` keeps an in-memory ring (cap 50) of warn/error
  lines (`logging.Recent()`, newest first; captured inside `logf` so every
  existing `Warnf`/`Errorf` call feeds it — no call sites changed). The
  heartbeat's `DeviceExtra` adds `problems`: recent log lines (messages
  truncated at 200 chars) + failed plugin installs from the install-status
  store, capped at 20 per report.
- **Cloud**: `deviceReport.problems` merged into `metadata.devices`
  **replace-on-report** (an empty digest clears resolved problems — no stale
  red flags). `StoreDetail.Problems` aggregates fleet-wide (device name
  attached, sorted newest first, capped 30). New **Problems & logs** card on
  the store page between fleet and remote management: Device / When / Level /
  Message table, calm empty state. i18n ×9 (6 new keys).

## Risk review

- Ring buffer is process-local memory only; restart clears it (matches
  "digest" semantics — persistent history is a later, deliberate feature).
- No secrets: the buffer holds already-logged text, and the no-secrets-in-logs
  rule covers what may be logged in the first place. Truncation caps payload.
- A replica/back-office device reports its own digest — per-device problems
  arrive naturally with the device name.
- Old till + new cloud: no `problems` field → nothing rendered. New till +
  old cloud: unknown JSON field ignored.

## Tests

- till: `logging` test — warn/error remembered newest-first, info excluded,
  cap enforced; suite + data-access guard green.
- mp: sync test — problems merged; device reporting an empty digest stays
  empty (replace semantics). Full `verify.sh` green.
