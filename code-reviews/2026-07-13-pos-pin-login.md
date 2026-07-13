# Review: POS PIN login, sessions, manager override (2026-07-13)

Implements `architecture/pos-auth.md` (spec committed first, ADR-0007) on
universal-till branch `feature/pos-auth`. Closes the top production-readiness
gap: `getSessionUserID` was hardcoded `'system'`, no login existed, and the
negative-inventory override trusted a free-text "Manager ID" input.

## What shipped

- **`internal/auth`** (new): PBKDF2-SHA256 PIN hashing (stdlib
  `crypto/pbkdf2`, 100k iter, per-user salt, constant-time compare, fails
  closed on unknown hash formats); SQLite-backed sessions (migration 006,
  token stored as SHA-256, 12h TTL, survive restart); device-wide lockout
  (5 failures → 30s); middleware gating every route except
  `/login`, `/api/auth/*`, `/public/*`, `/themes/*`, `/healthz`
  (pages → 303 `/login`, APIs → 401 on the `{data,error}` contract),
  operator injected into request context. `UT_AUTH=off` escape hatch
  (logged loudly) keeps CI/dev tooling working.
- **`internal/data/auth_repo.go`** (new): all auth SQL (users CRUD,
  sessions, purge) per the repository-pattern guard.
- **Login UI**: `/login` standalone full-screen numeric keypad
  (Alpine, offline-vendored assets, localized en+fa incl. RTL); first boot
  (no operator has a PIN) switches to one-time "set admin PIN" which creates
  a real `admin` operator — `system` stays a service identity and no default
  PIN ships. Nav gains an HTMX operator chip + Lock button.
- **`/users` admin page**: manager/admin only; add operators, set/reset PIN
  (PIN uniqueness enforced — PIN-only login must identify one operator; PIN
  change revokes sessions), activate/deactivate (revokes sessions; last
  active admin protected; managers manage only cashiers).
- **Attribution**: sales `cashierId` and shift/stock audit actors now default
  to the session operator. Negative-inventory override: manager/admin
  sessions self-authorize; cashiers supply `manager_pin` and the *manager*
  becomes the audit actor. Free-text Manager ID input replaced with a PIN
  field. Logins, failures, lockouts, logouts, user admin all audited.

## Review (self-review via /code-review, 6 findings) — dispositions

1. **CONFIRMED/fixed — manager-PIN brute-force oracle**: the override
   endpoint verified PINs with a per-request `auth.Service`, bypassing the
   login lockout. Fix: one shared `Service` on `common.Deps`; new
   `AuthorizeManager` routes through the same device-wide limiter (a wrong
   PIN of any role counts; manager approval during lockout refused). Pinned
   by `TestAuthorizeManager` + lockout test, and re-verified live: 5 bad
   override PINs → correct PIN refused with "too many attempts", keypad
   locked too.
2. **CONFIRMED/fixed — logout cookie MaxAge**: `-1` as `time.Duration`
   truncated to `MaxAge 0` (attribute omitted). Cookie helper now takes an
   int; logout sends `MaxAge -1`. (Was fail-closed regardless — empty token
   never resolves.)
3. **PLAUSIBLE/fixed — first-boot UNIQUE collision**: a dormant `admin`
   username row would 500 the setup; now reactivated and reused.
4. **PLAUSIBLE/fixed — unbounded sessions table**: `PurgeDeadSessions`
   (revoked or >7d-expired) runs best-effort on each session create.
5. **CONFIRMED/accepted — hardcoded "Manager PIN" label** breaks the
   no-hardcoded-strings rule, but the whole of inventory.html is already
   hardcoded English; localizing that page wholesale is a separate task.
6. **CONFIRMED/fixed — dead lockout-wait return** simplified to `bool`.

## Verified live (dev DB, pos.env.dev, auth on)

First boot → admin PIN → sale screen; unauthenticated `/` → 303 `/login`,
`/api/*` → 401 JSON; operator chip + Lock; cashier created via `/users`
(duplicate PIN refused), logs in, sale rows carry their id; cashier
override without/with wrong PIN → 403, with admin PIN → 200 and the admin
audited as actor; 5 bad PINs → lockout (audited); logout revokes; session
survives a POS restart; `UT_AUTH=off` restores open access with a warning.
Full audit trail observed: `first_boot_setup, login, login_failed ×5,
login_locked_out, logout, user_create, user_pin_set`.

## Known follow-ups (tracked in spec "out of scope")

Idle auto-lock timer; per-page role permissions; localized inventory page;
manager-PIN prompt as a reusable keypad partial for void/refund/price
override; PIN change UX for operators themselves.
