# Code review — marketplace browser OIDC login (G21)

Date: 2026-07-15
Author: Claude (autonomous session), for Farshid
Repo: ut-market-place
Scope: `internal/webauth/*` (new), `internal/config/config.go`,
`internal/auth/middleware.go`, `internal/httpapi/router/router.go`,
`internal/api/server.go`, `internal/api/templates/index.html`, tests.
Spec: `docs/architecture/marketplace-oidc-login.md`. ADR: 0012 (accepted).

## What & why

Follows the role-based UI access change (`fc642db`): that gated `/ui/admin` and
`/ui/vendor` by role but browsers had no way to *obtain* a principal. This adds
the browser login (authorization-code + PKCE, Zitadel) that produces one.

New self-contained `internal/webauth` package:
- `session.go` — `Session` + NaCl-secretbox sealer (authenticated encryption)
  for the `ut_session` cookie.
- `flow.go` — sealed short-lived `flowState` (state/nonce/PKCE verifier/returnTo)
  for the `ut_oidc_flow` cookie.
- `roles.go` — extracts role names from Zitadel's project-roles claim (+ plain
  `roles` fallback).
- `webauth.go` — `Authenticator`: `New` (OIDC discovery + verifier),
  `Register` (`/ui/login`, `/ui/auth/callback`, `/ui/logout`), `Inject`
  (best-effort principal), `Guard(roles…)` (enforce + redirect/403).

`internal/auth` gains `NewPrincipal` + `ContextWithPrincipal` so a non-JWT
authenticator can inject an `*auth.Principal` that `FromContext`, the guards and
the templates already read. The router reverts to skipping all of `/ui/` at the
outer JWT middleware and moves staff-area enforcement inside via `webauth.Guard`,
so browser sessions (cookie, no Bearer header) aren't 401'd at the edge.

## Security review

- **Session confidentiality + integrity:** NaCl secretbox (XSalsa20-Poly1305)
  under a 32-byte key; fresh random nonce per seal. Tamper and wrong-key both
  fail to open (tested). Cookie is httpOnly, `Secure` (when redirect URL is
  https), SameSite=Lax, with an embedded expiry that `Valid()` enforces
  independently of the cookie MaxAge.
- **CSRF / replay on the flow:** `state` is 256-bit random, bound in the sealed
  flow cookie and checked on callback; `nonce` is bound into the auth request
  (`oidc.Nonce`) and checked against the verified ID token; PKCE S256 verifier
  is carried in the sealed flow cookie, never exposed. Flow cookie is 10-min TTL
  and cleared on callback.
- **Token validation:** ID token verified by `go-oidc` (signature via issuer
  JWKS, `aud`=client id, `exp`, issuer). We never trust unverified claims.
- **Open-redirect:** `returnTo` is sanitized to same-site `/ui/…` or
  `/merchant…` only; everything else falls back to `/ui/` (tested).
- **No token hoarding:** access/refresh tokens are discarded after the ID-token
  read; the session is minimal (sub/name/email/roles/exp).

## Non-regression

- Feature OFF unless `AUTH_WEBLOGIN_{CLIENT_ID,REDIRECT_URL,COOKIE_KEY}` set;
  `webauth.New` returns a disabled authenticator and `Register` is a no-op.
- `Guard` short-circuits open when `AUTH_DISABLED=true` (current prod) — no
  lockout. Verified by `TestGuardAuthDisabledPassthrough`.
- Live Zitadel OIDC discovery (`id.universaltill.com`) was fetched to ground the
  endpoints/PKCE support before implementation.

## Tests

`internal/webauth`: seal round-trip, tamper + wrong-key rejection, expiry,
role extraction (Zitadel claim + array fallback), `sanitizeReturnTo`, and Guard
behaviour (auth-disabled passthrough, valid-role served, wrong-role 403, no
session → 302 login). `internal/auth` and `internal/httpapi/router` updated and
green. `scripts/ci/verify.sh` passes (gofmt, vet, golangci-lint, tests,
contract).

## Not done here (documented in the spec)

- **Not yet validated end-to-end against a live Zitadel app** — the OIDC app +
  project roles must be created in the console (runbook in the spec) and the env
  set; I can't create the app without a console session/PAT. The roles claim
  shape depends on enabling "Assert Roles on Authentication".
- Merchant portal still uses its own portal-token model (future: same session).
- Fixed session lifetime, no refresh-token rotation yet.
