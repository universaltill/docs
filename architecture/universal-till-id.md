# Universal Till ID — single sign-on for the whole platform (proposal — G21)

Status: **direction decided 2026-07-15 — ADR-0012: built IN-HOUSE** as our
own Go OIDC provider (`ut-id`). Hosted identity (Azure B2C/Entra) and
self-hosted third-party IdPs (Zitadel/Keycloak) were both rejected by
Farshid: "I don't want to be related to any 3rd party. I want OIDC on my
system." The "Build shape" section below is superseded by ADR-0012.

## What it is

One identity provider ("**Universal Till ID**") that every surface signs in
with: the consumer app (G13/G16 shoppers), the merchant portal, the
marketplace admin/review console (G20 reviewers), the websites, back-office
and headquarter apps (G18/G19) — and optionally the POS.

- **Standard OIDC / OAuth 2.0** — one account, tokens with roles/scopes.
- **Role-based**: shopper, merchant-owner, merchant-staff,
  plugin-developer, ut-reviewer, ut-admin. Apps authorize on scopes, never
  on local user tables.
- **Two-factor**: passkeys/WebAuthn first (phones already have them), TOTP
  fallback; required for merchant, developer and UT-staff roles.
- **Device flow** (OAuth 2.0 Device Authorization Grant): a till or kiosk
  shows a short code/QR → the owner approves on their phone → the device
  is signed in without typing a password on a shop screen. This is also
  the natural mechanism for zero-touch device enrolment (phase D pairing).

## The POS red line (offline-first, ADR-0003)

Checkout and operator PIN login **never depend on the cloud**. Universal
Till ID on the POS is optional and additive: a merchant links their till to
their account via device flow (for cloud services: sync, backup, consumer
features); cashier PINs stay local and keep working with the internet down.

## Build shape (decide with Farshid)

- **Recommend self-hosting an open-source IdP** (Zitadel or Keycloak —
  both do OIDC, RBAC, passkeys, TOTP and device flow out of the box)
  rather than writing our own crypto-sensitive auth server. Runs on the
  homelab for dev, Azure for prod; fits the no-vendor-lock-in stance.
- The marketplace's enforced-auth mode **already validates JWTs via
  `AUTH_JWKS_URL`** — pointing it at the IdP's JWKS is exactly the
  integration it was built for; merchant portal tokens then retire.
- Consumer app account (phone/email, per-shop consent records in the
  consumer-app proposal) = a shopper-role Universal Till ID.

## Rollout order

1. IdP stood up + marketplace admin/review console behind it (small user
   count, immediate G20 dependency).
2. Merchant portal (replaces portal-token bar).
3. Consumer app accounts at app launch.
4. POS device-flow linking with the cloud-sync tier.
