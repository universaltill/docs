# Marketplace merchant auth: per-merchant portal tokens

Spec (ADR-0007 document-first) for closing the marketplace production gap:
the merchant entitlement endpoints (`/ui/api/merchant/entitlements{,/approve,/revoke}`)
are fully open — anyone who can reach the marketplace can approve or revoke
any merchant's plugin entitlements and read what a merchant has approved.

## Goals

A real credential per merchant organization, without building full merchant
IAM yet. Dev stays fluent: with `AUTH_DISABLED=true` (the default, and how
the homelab dev marketplace runs) behaviour is unchanged.

Out of scope (later): merchant user accounts/SSO, per-user roles within a
merchant, vendor portal auth, replacing the admin upload bearer.

## Design

**Credential.** `MerchantOrganization` gains an optional
`portal_token_hash` (SHA-256 hex of an opaque token; plaintext never
stored). One token per merchant org — it authenticates *the organization*,
mirroring how the admin upload bearer authenticates the operator of the
marketplace.

**Issuance (admin).** `POST /ui/api/admin/merchants/portal-token`
(form: `merchant_id` = external id), gated by the existing admin bearer
(`authorizeUpload`). Generates a 32-byte random token, stores the hash
(rotating any previous token), auto-provisions the merchant org if new
(same as the entitlement approve path), and returns the plaintext token
once in the response.

**Enforcement.** New `authorizeMerchant(r, merchantExternalID)`:

- `AUTH_DISABLED=true` → allow (dev parity; the flag already exists).
- Otherwise require `Authorization: Bearer <token>` with
  SHA-256(token) equal to that merchant org's `portal_token_hash`
  (constant-time compare). No org, no hash set, or mismatch → 401 on the
  `{data,error}` contract. Fail closed.

Applied to all three merchant entitlement endpoints (approve, revoke, and
the read-only list — it reveals a merchant's approved estate). The token
in the request must match the `merchant_id` being operated on, so one
merchant's token cannot touch another's entitlements.

**Portal UI.** The merchant plugins page gets a portal-token control (like
the review queue's admin-token bar): stored in `localStorage`, sent as the
Authorization header by the approve/unapprove fetch. Empty token + auth
enabled → the API's 401 message is surfaced.

**POS.** New optional `UT_MARKETPLACE_MERCHANT_TOKEN`; the store page's
entitled-listings fetch sends it as a bearer when set. If the marketplace
gates the endpoint and the POS has no/wrong token, the existing fallback
kicks in (full catalog shown); installs are still blocked server-side for
unentitled paid/revoked listings via the download-token path, and free
listings still self-acquire — same trust posture as today, minus the
entitled-only filtering.

## Acceptance

- `AUTH_DISABLED=true`: everything works exactly as before, no token
  anywhere.
- Auth enabled: approve/revoke/list without a token → 401; with another
  merchant's token → 401; with the right token → works.
- Admin issues/rotates a token via the admin bearer; old token stops
  working after rotation.
- POS with the token configured filters the store to entitled listings;
  without it, falls back to the full catalog.
