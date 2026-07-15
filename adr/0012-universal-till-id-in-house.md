# 0012 — Universal Till ID is built in-house (own Go OIDC provider)

**Status:** accepted (2026-07-15, Farshid: "I don't want to be related to
any 3rd party. I want OIDC on my system.")

## Context

Every cloud-side surface (marketplace console, merchant portal, consumer
app, back-office/HQ apps, POS device-flow linking) needs one sign-in with
roles and 2FA (G21). Three shapes were considered:

1. **Hosted identity service** (Azure B2C / Entra External ID — free
   ≤50k MAU): rejected. Microsoft would hold every user account, logins
   would depend on their cloud, and leaving later means resetting every
   user's credentials. Maximum lock-in in the most critical component.
2. **Self-hosted open-source IdP** (Zitadel/Keycloak): prepared, then
   rolled back on Farshid's decision. Still a third-party product at the
   heart of the platform (own upgrade treadmill, licence drift — Zitadel
   moved toward AGPL — and a ~1 GB always-on footprint on the Pi cluster).
3. **In-house provider**: chosen.

## Decision

Build **`ut-id`**: our own Go OIDC provider. What makes DIY identity
defensible here — normally it isn't — is a **closed, first-party world**:
we control every client, so ut-id implements a small fixed profile and
refuses everything else:

- OIDC discovery + JWKS (asymmetric signing, key rotation).
- Authorization-code **with PKCE required**; no implicit, no hybrid, no
  client secrets in public clients, **no dynamic client registration** —
  clients are rows we seed.
- **Device authorization grant** (tills/kiosks link via short code/QR).
- Password auth (argon2id) + **TOTP** 2FA; brute-force lockout shared
  with login (same lesson as POS PIN auth). Passkeys/WebAuthn come later
  and may use one focused library — explicitly flagged for approval.
- Roles as claims (`shopper`, `merchant-owner`, `merchant-staff`,
  `plugin-developer`, `ut-reviewer`, `ut-admin`); apps authorize on
  claims, never local user tables.
- Ordinary Go module dependencies remain acceptable (the rejected thing
  is third-party identity *products/services*, not code libraries).

**The POS red line stands (ADR-0003):** cashier PIN login and checkout
never depend on ut-id or any network. ut-id serves cloud surfaces only.

## Consequences

- We own the security burden: the constrained profile, mandatory review
  of every auth change, and rate limiting are the mitigations. The
  attack surface is a fraction of a general-purpose IdP's.
- The marketplace's existing `AUTH_JWKS_URL` validation slots straight
  onto ut-id's JWKS — the integration it was built for.
- Runs on the homelab (dev) and later Azure (prod); SQLite first like
  every other component, Postgres if scale ever demands it.
- Repo: `ut-id` (universaltill org), same CI/review standards as
  universal-till and ut-market-place.
