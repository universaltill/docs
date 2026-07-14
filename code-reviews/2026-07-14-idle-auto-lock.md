# Review — idle auto-lock (pos-auth increment)

Date: 2026-07-14 · Repo: universal-till · Spec: `architecture/pos-auth.md`
§ "Idle auto-lock" (written first, ADR-0007).

## What shipped

- Migration 010: `sessions.last_seen_at` (backfilled from `created_at`).
- `AuthRepo`: `LookupSession` returns `LastSeenAt`
  (`COALESCE(last_seen_at, created_at)`, both timestamp formats accepted);
  new `TouchSession`.
- `auth.Service`: `SetIdleLockMinutes` (atomic, hot-reloadable),
  `Resolve` revokes sessions idle past the window (server authoritative —
  pages 303 → `/login`, APIs 401 via the unchanged middleware) and fires
  the `SetIdleLockAudit` hook (wired to `audit_log` `user`/`idle_lock` in
  pages.Init, keeping the auth package SQL-free).
- Activity refresh: `last_seen_at` touched when older than
  `min(60s, window/4)` — never a write per request, and the throttle can't
  eat the window (the spec's flat "once per minute" would let a 1-minute
  window lock an *active* operator; caught during implementation).
- Setting `auth.idle_lock_minutes` (default **10**, 0 = off): Settings page
  card (manager/admin only, `isManager` render gate + 403 on the endpoint),
  `POST /api/settings/idle-lock`, persisted via the normal settings path,
  applied immediately to the service and the template layer.
- Cosmetic client timer: `data-idle-lock` on `<body>` (absent when off or
  `UT_AUTH=off`), `app.js` redirects to `/login` after the window with no
  activity (pointer/key/touch/wheel). Never blocks; `/login` excluded.
- 5 i18n keys en+fa.

## Findings / notes

1. **Touch-throttle vs window interaction** (above) — deviated from the
   spec's literal "at most once per minute" for correctness; spec updated.
2. Enabling the feature after a long UT_AUTH-on idle period can lock
   sessions on their next request (their `last_seen_at` is old). Accepted:
   one re-login, and it is exactly what the feature promises.
3. Test schemas in `auth_test.go`/`auth_page_test.go` gained the new
   column (they hand-roll `sessions`).

## Verification

- Unit: idle past window → locked + audited + revocation permanent;
  window 0 → long-idle session survives; activity inside the window
  refreshes `last_seen_at`; `touchInterval` table test. Full
  `go test ./...` + both CI guards green.
- Live E2E (fresh DB, auth ON, first-boot wizard): default renders
  `data-idle-lock="600"`; set 1-minute window as admin → aged session:
  page 303 → `/login`, API 401 JSON, `idle_lock` audit row; **re-login →
  basket intact** (spec acceptance); `minutes=0` → 3-hour-idle session
  still valid and attribute gone; cashier: card hidden + endpoint 403.
