# 0003 — Offline-first POS

**Status:** accepted (long-standing; recorded 2026-07-10)

## Decision
A full sale completes with no network: checkout never blocks on connectivity;
sync is queued and retried; offline/sync state surfaces as chips, never modal
blockers. All web assets (htmx, alpine, fonts, CSS) are **vendored** — no CDN.
Catalog snapshots and plugin bundles are cached on disk.
