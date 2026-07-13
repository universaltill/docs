# Review: merchant portal tokens gate the entitlement endpoints (2026-07-13)

Implements `architecture/marketplace-merchant-auth.md` (spec committed
first). Closes the marketplace production gap: the merchant entitlement
endpoints (approve / revoke / entitled-list) were fully open — anyone
reaching the marketplace could manage any merchant's entitlements.

## What shipped

**ut-market-place** (branch `feature/merchant-portal-token`):

- `MerchantOrganization.portal_token_hash` (ent schema, sensitive,
  regenerated code). Plaintext never stored.
- `internal/merchantauth`: `IssueToken` (32-byte token, auto-provisions the
  org like self-serve acquire; rotation overwrites) and `Verify`
  (SHA-256 + constant-time compare; unknown merchant / no token on file
  fail closed).
- `api.WithMerchantAuth(svc, enforce)` — enforcement follows
  `!AUTH_DISABLED`, so the dev marketplace (disabled) behaves exactly as
  before. All three merchant entitlement handlers now call
  `authorizeMerchant(r, merchantID)`: bearer must be *that* merchant's
  token; 401 on the `{data,error}` contract otherwise.
- Admin issuance: `POST /ui/api/admin/merchants/portal-token`
  (admin upload bearer) returns the plaintext token once.
- Portal UI (discovery.html): "Portal token" control persisted in
  localStorage, sent as the Authorization header by approve/unapprove.
- **Pre-existing bug found & fixed while E2E-testing enforced mode**:
  `auth.AllowUnauthenticatedPaths` matched exactly, but the router passes
  `"/ui/"` expecting a prefix — with auth enabled the ENTIRE portal
  (including the CI upload endpoint, which has its own bearer, and the
  signing-key endpoint) was locked behind JWT with no JWT issuance in
  existence, so enforced mode was unusable. Trailing-slash entries are now
  prefixes; the device API (`/api/…`) stays behind JWT. Pinned by
  `TestSkipperPrefixEntries`.

**universal-till** (branch `feature/merchant-portal-token`):

- `UT_MARKETPLACE_MERCHANT_TOKEN` → `Marketplace.MerchantToken`; the store
  page's entitled-listings fetch sends it as a bearer. Without/with a wrong
  token the existing full-catalog fallback applies (installs remain
  server-side-gated by the download-token path). pos.env.dev documents it
  (unset on dev).

## Tests

`internal/merchantauth`: issue/verify, rotation invalidates, fail-closed
without token / unknown merchant, single org row after rotation.
`internal/api`: enforced 401 (no/wrong/cross-merchant token), 200 with the
right token, read-only list gated, open when disabled, admin issuance
requires the admin bearer. `internal/auth`: skipper prefix semantics.
verify.sh green (gofmt, vet, golangci-lint, suites, contract guard).

## Verified live (local instance, AUTH_DISABLED=false, TLS dev cert)

Approve/list without token → 401 (from the merchant gate, JSON contract) →
admin bearer issues a 64-hex token → approve passes auth (404 on unknown
listing), list 200 → merchant-1's token refused for merchant-2 → rotation:
old 401, new 200 → `/api/v1/catalog/plugins` still 401 (JWT). The deployed
dev marketplace is unaffected (runs `AUTH_DISABLED=true`; unit test pins
the open path).

## Deployment note

No behaviour change on the dev cluster until `AUTH_DISABLED=false` is set
there. Turning auth on now requires only: JWKS URL for the device API, and
issuing portal tokens to merchants (admin endpoint) + `UT_MARKETPLACE_MERCHANT_TOKEN`
on tills.
