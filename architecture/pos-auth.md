# POS authentication: PIN login, sessions, manager override

Spec (ADR-0007 document-first) for closing the top production-readiness gap:
the till has a `users` table with `pin_hash` but no login, and
`getSessionUserID` is hardcoded to `system`.

## Goals

Touch-first cashier sign-in like a real till: walk up, tap your PIN, sell.
Every audited action (sales, shifts, stock, overrides) carries the real
operator. Manager-gated actions ask for a manager PIN instead of trusting a
free-text "Manager ID" (today's negative-inventory override form).
Fully offline (ADR-0003): no network involved anywhere in auth.

Out of scope (later): per-page role permissions, idle auto-lock timer,
multi-till user sync, card/NFC operator login.

## Design

**Identity = PIN.** The login screen is a numeric keypad; the PIN alone
identifies the operator (classic till UX — no username step). PINs are
4–8 digits, unique across active users (enforced when a PIN is set).

**Hashing.** `pin_hash` = PBKDF2-SHA256, per-user random 16-byte salt,
100k iterations, stored as `pbkdf2$sha256$<iter>$<salt-b64>$<hash-b64>`
(stdlib `crypto/pbkdf2`, no new deps). A short numeric PIN cannot survive
offline brute force at any hash cost, so the real defence is online rate
limiting: 5 failed attempts per device → 30s lockout (in-memory), every
failure audited.

**Sessions.** Server-side, SQLite-backed (survives POS restart —
offline-first). New `sessions` table (migration): `id`, `token_hash`
(SHA-256 of the opaque cookie value; raw token never stored), `user_id`,
`created_at`, `expires_at`, `revoked_at`. Cookie `ut_session`: HttpOnly,
SameSite=Lax, Path=/ (no `Secure` flag — tills serve plain HTTP on
localhost/LAN). Expiry 12h absolute; lock/logout revokes server-side.

**Middleware.** `pages.Init` wraps the mux; the auth check runs before
every route except: `/login`, `/api/auth/*`, `/public/*`, `/themes/*`,
`/healthz`. Browser requests without a valid session → 303 to `/login`;
`/api/*` → 401 JSON. The authenticated user (id, role, display name) is
injected into the request context; `auth.UserID(r)` / `auth.User(r)`
replace the `getSessionUserID` stub. Escape hatch `UT_AUTH=off` disables
the middleware (CI/dev tooling); default is ON.

**First boot.** If no active user has a PIN, `/login` switches to a
one-time "set admin PIN" form (choose PIN twice → sets it on the seeded
admin user, creates the session). No default PIN ships anywhere.

**Manager override.** Actions requiring manager/admin when the session
user is a cashier accept a `manager_pin` field, verified against
manager/admin users; the audit actor for the override is the manager who
approved, and the audit payload records the cashier session it happened in.
First consumer: negative-inventory override (replaces the free-text
Manager ID input). The keypad prompt is a reusable partial for future
gated actions (void, refund, price override).

**Attribution.** Sales `cashierId` and shift `cashier_id` default to the
session user (explicit request values still win, for device integrations).
The `system` user remains for till-initiated writes (sync jobs, plugin
events).

**UI.** `/login`: full-screen keypad (HTMX post, Alpine for input state),
localized, kiosk-safe. Nav gains the operator chip (display name) + Lock
button (revokes session → `/login`). Users admin page (`/users`, menu
item, manager/admin only): list users, add user (username/display/role),
set/reset PIN, activate/deactivate. Deactivating revokes the user's
sessions; the last active admin cannot be deactivated (nor can `system`
be edited).

## Idle auto-lock (increment, 2026-07-14)

Promoted from "out of scope": a till left unattended must not stay signed
in. Design keeps auth fully offline and the checkout path unblocked:

- **Setting** `auth.idle_lock_minutes` (integer, `0` = disabled;
  default **10**), editable on the Settings page (manager/admin section)
  through the normal settings-save path.
- **Server side is authoritative.** `sessions` gains `last_seen_at`
  (append-only migration). The auth middleware compares
  `now − last_seen_at` against the configured window on every request:
  stale sessions are revoked exactly like Lock (pages → 303 `/login`,
  APIs → 401 JSON). `last_seen_at` is refreshed when older than
  `min(60s, window/4)` — no write per request on SQLite, and the throttle
  always stays well under the window (a flat once-per-minute refresh would
  let a 1-minute window lock an operator who was active 59s ago).
- **Client side is cosmetic.** A small idle timer in `app.js` (reset on
  pointer/key/touch activity) redirects to `/login` when the window
  elapses, so an abandoned till visibly locks without waiting for the
  next request. The timer reads the window from a `data-idle-lock`
  attribute; it never blocks and is absent when the feature is off.
- **Basket survives.** The sale engine is server-side state; locking
  mid-sale then signing back in returns to the same basket (same
  behaviour as the manual Lock button today).
- Lock events are audited (`auth.session.idle_lock`).

Acceptance: with a 1-minute window set, an idle till redirects to the
keypad and its next API call 401s; activity keeps the session alive past
the window; `0` disables both mechanisms; basket contents are intact
after re-login.

## Acceptance

- Fresh DB → first boot asks for admin PIN → lands on sale screen.
- Cashier PIN → session survives POS restart; Lock → keypad; wrong PIN ×5
  → 30s lockout (audited).
- Sale + shift audit rows carry the logged-in operator, not `system`.
- Cashier attempting negative-inventory override is asked for a manager
  PIN; approval audits the manager as actor.
- `/api/*` without session → 401 JSON; pages → redirect `/login`;
  `UT_AUTH=off` restores today's behaviour for tooling.
