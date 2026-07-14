# Review — self-service PIN change (P1.2, pos-auth follow-up)

Date: 2026-07-14 · Repo: universal-till. Closes the last small item on the
pos-auth spec's out-of-scope list.

## What shipped

- `auth.Service.ChangeOwnPIN(userID, current, new)`: current PIN proves
  identity (wrong attempts count against the **shared device lockout** —
  no new brute-force oracle), new PIN format-validated and unique across
  operators (login is PIN-only), all the user's sessions revoked on
  success (changed credential invalidates sessions).
- `/pin` page (any signed-in operator; the operator's name in the session
  chip is now the link) + `POST /api/pin/change` with per-cause error
  redirects; success clears the cookie → sign in with the new PIN.
  Audited: `pin_changed` / `pin_change_failed` / `pin_change_locked_out`.
  6 i18n keys en+fa.

## Bug caught by the E2E (fixed before commit)

First mount was `POST /api/auth/pin/change` — the `/api/auth/` prefix is
**middleware-exempt** (login flow), so the handler never saw an
authenticated operator and silently did nothing. Moved to
`/api/pin/change`. Lesson recorded: nothing needing a session may live
under an exempt prefix.

## Verification

- Unit: wrong current PIN → ErrInvalidPIN (and counted), taken PIN →
  ErrPINTaken, short PIN rejected, success kills the old session + old
  PIN and the new PIN logs in. Full suite + guards green.
- Live E2E (cashier jo): wrong-current / taken / mismatch each redirect
  to `/pin?err=…`; success → old session dead, old PIN refused, new PIN
  logs in; audit rows present. Dev-DB note: jo's PIN is now **2222**.
