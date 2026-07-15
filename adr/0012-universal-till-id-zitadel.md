# 0012 — Universal Till ID runs on self-hosted Zitadel

**Status:** accepted (2026-07-15). Decided in two steps the same day:
Farshid first chose in-house ("I don't want to be related to any 3rd
party. I want OIDC on my system") and an in-house Go provider (ut-id)
was built and E2E-tested; after clarifying that zitadel.com/pricing is
their HOSTED cloud and self-hosting is free, he approved self-hosted
Zitadel ("If you think zitadel is good … go and use it") and asked for
the ut-id spike to be deleted.

## Context

Every cloud-side surface (marketplace console, merchant portal, consumer
app, back-office/HQ apps, POS device-flow linking) needs one sign-in with
roles and 2FA (G21). Three shapes were considered:

1. **Hosted identity service** (Azure B2C / Entra External ID — free
   ≤50k MAU): rejected. Microsoft would hold every user account, logins
   would depend on their cloud, and leaving later means resetting every
   user's credentials. Maximum lock-in in the most critical component.
2. **In-house provider**: built as a working spike (full code+PKCE flow
   E2E-tested) — proved feasible for the constrained first-party profile,
   but the long tail the consumer app needs (passkeys, account recovery,
   email verification, admin console) is exactly the code we'd least want
   to own. Deleted on Farshid's request once Zitadel was chosen.
3. **Self-hosted open-source IdP (Zitadel)**: chosen.

## Decision

Run **self-hosted Zitadel** (open source, pinned v3.x, single container
with built-in login) on our own infrastructure — homelab for dev
(id.home.taskrunnertech.co.uk, homelab-k8s app `zitadel`), Azure later
for prod. It is "on our system": accounts live in our Postgres on our
hardware; the pricing page applies only to their hosted cloud. What we
get out of the box: OIDC/OAuth2 (code+PKCE, device flow), passkeys,
TOTP, account recovery, an admin console, and role management — roles
(`shopper`, `merchant-owner`, `merchant-staff`, `plugin-developer`,
`ut-reviewer`, `ut-admin`) ride as claims; apps authorize on claims,
never local user tables. Upgrades are deliberate (pinned versions),
never automatic. **Hosted identity services (Azure B2C/Entra, Auth0,
Cognito) are permanently rejected.**

**The POS red line stands (ADR-0003):** cashier PIN login and checkout
never depend on ut-id or any network. ut-id serves cloud surfaces only.

## Consequences

- We operate but don't write the crypto-sensitive code; upstream carries
  most of the security burden. We pin versions and upgrade deliberately.
- The marketplace's existing `AUTH_JWKS_URL` validation slots straight
  onto Zitadel's JWKS — the integration it was built for (increment 2:
  marketplace console behind it).
- ~1 GB + its own Postgres on the Pi cluster — acceptable now, moot once
  the N150 boxes arrive.
- If Zitadel ever becomes an obstacle, the in-house profile is proven
  buildable (the spike passed a full E2E before deletion).
