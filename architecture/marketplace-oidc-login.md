# Marketplace browser OIDC login (G21, ADR-0012)

Puts the marketplace **console** (`/ui/admin`, `/ui/vendor`) behind Universal
Till ID (self-hosted Zitadel at `id.universaltill.com`). Storefront browsing and
the merchant portal stay public. Implements the increment ADR-0012 anticipated:
"the marketplace console behind it".

## How it works

Authorization-code + PKCE, with a sealed session cookie:

1. A visitor hits a staff area → `webauth.Guard` finds no principal →
   302 to `/ui/login?returnTo=…`.
2. `/ui/login` generates `state`, `nonce`, PKCE verifier; seals them in a
   short-lived `ut_oidc_flow` cookie; redirects to Zitadel `/oauth/v2/authorize`.
3. Zitadel authenticates the user and redirects to `/ui/auth/callback`.
4. The callback validates `state`, exchanges the code (PKCE) for tokens,
   verifies the **ID token** (signature via JWKS, `aud`, `exp`, `nonce`),
   extracts `sub`/`name`/`email` and **roles** from the Zitadel project-roles
   claim, and seals a small session into the `ut_session` cookie
   (NaCl secretbox, httpOnly, Secure, SameSite=Lax, 8 h default).
5. Every `/ui/` request runs `webauth.Inject` (best-effort): a valid session →
   an `*auth.Principal` in context, so the storefront nav is role-aware and the
   guards enforce. A Bearer token still works too (APIs) — both paths feed the
   same `auth.Principal`, so the existing `RequireRoles`/role model is unchanged.

Role → area mapping (marketplace RBAC role names):
- `/ui/admin`  → `vendor_reviewer`, `internal_compliance`
- `/ui/vendor` → `vendor_maintainer`, `vendor_reviewer`, `internal_compliance`

## Non-breaking

The feature is **OFF** unless `AUTH_WEBLOGIN_CLIENT_ID`,
`AUTH_WEBLOGIN_REDIRECT_URL` and `AUTH_WEBLOGIN_COOKIE_KEY` are all set. When off,
or when `AUTH_DISABLED=true` (current prod), the guards short-circuit open — the
marketplace behaves exactly as before. No lockout is possible from this change
alone.

## Configuration (env)

| Env var | Required | Value |
|---|---|---|
| `AUTH_WEBLOGIN_CLIENT_ID` | yes | Zitadel web-app client id |
| `AUTH_WEBLOGIN_REDIRECT_URL` | yes | `https://cloud.universaltill.com/ui/auth/callback` (canonical since 2026-07-20) |
| `AUTH_WEBLOGIN_EXTRA_REDIRECT_URLS` | no | space-separated extra hosts kept working, e.g. `https://marketplace.universaltill.com/ui/auth/callback` (the till fleet's legacy host) — a login started on one of these completes on the SAME host instead of bouncing to `AUTH_WEBLOGIN_REDIRECT_URL`'s host |
| `AUTH_WEBLOGIN_COOKIE_KEY` | yes | base64 of 32 random bytes (`openssl rand -base64 32`) |
| `AUTH_WEBLOGIN_ISSUER_URL` | no (falls back to `AUTH_ISSUER_URL`) | `https://id.universaltill.com` |
| `AUTH_WEBLOGIN_CLIENT_SECRET` | no (PKCE public client) | client secret if a confidential app |
| `AUTH_WEBLOGIN_POST_LOGOUT_URL` | no | `https://cloud.universaltill.com/ui/` |
| `AUTH_WEBLOGIN_EXTRA_SCOPES` | no | extra scopes (space/comma sep) |
| `AUTH_WEBLOGIN_SESSION_TTL` | no (8h) | browser session lifetime |

Store `AUTH_WEBLOGIN_COOKIE_KEY` (and any client secret) in Key Vault →
sealed-secret, like the other marketplace secrets.

## Runbook — create the Zitadel app (console, ~5 min)

Log in at `id.universaltill.com` as `admin@universaltill.id.universaltill.com`.

1. **Project**: create (or reuse) a project, e.g. `Marketplace`. Enable
   **"Assert Roles on Authentication"** and **"Check authorization on
   Authentication"** so granted roles are asserted in the token.
2. **Roles**: add project roles whose keys match the RBAC names exactly:
   `merchant_admin`, `merchant_operator`, `vendor_maintainer`,
   `vendor_reviewer`, `internal_compliance`.
3. **Application** → **Web** → **PKCE** (public client, no secret) — or Code +
   client secret for a confidential app. Register a redirect URI **per
   hostname the console answers on** — today that's
   `https://cloud.universaltill.com/ui/auth/callback` (canonical) and
   `https://marketplace.universaltill.com/ui/auth/callback` (till fleet
   legacy alias); same pair for the post-logout URIs
   (`.../ui/` on each host). Copy the **Client ID**.
4. **Grant yourself a role**: in the project, authorize your admin user with
   `internal_compliance` (and `vendor_reviewer` to see the review queue).
5. Set the env vars above on the marketplace deployment (Client ID + a fresh
   cookie key), redeploy. Visit `/ui/admin/reviews` → you should be bounced to
   Zitadel, sign in, and land back in the console.

## Notes / follow-ups

- Roles come from the ID token's `urn:zitadel:iam:org:project:roles` claim
  (keys = role names). If you prefer per-project scoping, the code also reads
  `urn:zitadel:iam:org:project:<id>:roles` and a plain `roles` array.
- Access/refresh tokens are not stored; the session is self-contained and
  re-derived from the sealed cookie. Session lifetime is fixed (no silent
  refresh) — re-login after `SESSION_TTL`. Refresh-token rotation is a possible
  later increment.
- The merchant portal (`/merchant`) still uses its own portal-token model; wiring
  it to the same session is a follow-up.
