# Review — Marketplace Playwright UI E2E suite

**Date:** 2026-07-18 · **Repo:** ut-market-place · **Branch:** feat/mp-playwright → main

## What

Real-browser suite mirroring the till's (`universal-till/e2e`): 4 specs in
headless Chromium against a throwaway sqlite marketplace booted by
`e2e/run-mp.sh`, wired into CI (`.github/workflows/e2e.yml`).

- `storefront.spec.ts` — anonymous storefront renders **all** seeded cards +
  all three trust pills, no template errors, **zero approve buttons for
  anonymous visitors**; search filters to exactly one card.
- `portal.spec.ts` — self-host portal approve → revoke round-trips on a card
  (the "dead buttons" field bug, driven end-to-end); plugin detail page
  renders the real listing by slug with a live approve button.

## Bugs found while building it (all in the harness/specs, one real gap)

1. **Seed race** — Playwright starts specs the instant the health URL answers;
   seeding after boot inside run-mp.sh raced the first spec. Fix: three-phase
   boot (schema boot on :8094 → kill → seed → real server on :8093).
2. **`go run` leaks its child** — killing the `go run` wrapper left the server
   holding the port; phase 3 then failed to bind. Fix: `go build` once, run
   the binary.
3. **UUID form matters** — ent compares canonical dashed UUID strings;
   `hex(randomblob(16))` seed IDs render fine but are never found by `IDEQ`.
   Approve returned "listing not found" until seeds used dashed UUIDs.
4. **`merchant-1` org must exist** — the anonymous self-host viewer resolves
   to external_id `merchant-1`; approve 500s ("merchant organization not
   found") on a fresh DB without it. This is worth remembering for self-host
   installs generally: a virgin DB has no default org until a claim happens.
5. **Search-term substring trap** — "Verified" matches "Unverified" too.

## Why it matters

The truncated-storefront `$.T` bug reached prod because no test rendered a
populated index in a browser. This suite renders it, in CI, on every push.

## Verification

- `npx playwright test` — 4 passed, twice back-to-back (6.4s / 6.3s).
- Suite conventions: workers=1 (shared server state), watchConsole fails any
  spec on a browser console error, screenshots/traces retained on failure.
