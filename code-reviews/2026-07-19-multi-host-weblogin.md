# Review: multi-host web login (cloud.universaltill.com keeps its session)

**Date:** 2026-07-19 · **Repo:** `ut-market-place` · **Branch:** `feat/multi-host-weblogin`
**Trigger:** Farshid — "cloud.universaltill.com/ui works but when I login with id
it goes back to the market" (task #40).

## Root cause

Two layers, both by design until now:

1. `webauth.canonicalLoginURL` deliberately bounces a login started on any
   non-canonical host to `RedirectURL`'s host — the 2026-07-17 fix for the
   "login session expired" field bug (flow cookie set on a host the callback
   never returns to). So `/ui/login` on cloud.* hopped to marketplace.*, the
   whole flow completed there, and the session cookie was minted for the
   marketplace host.
2. Zitadel only had the marketplace redirect URIs registered; the cloud
   callbacks were merged into `infra/unitill-infra/zitadel/marketplace.tf` but
   that root has no CI (needs the machine-user PAT) and was never applied.

## Changes (marketplace)

- `config.WebLoginConfig.ExtraRedirectURLs` (+ env
  `AUTH_WEBLOGIN_EXTRA_REDIRECT_URLS`, space-separated like the scopes list):
  one registered redirect URL per additional public hostname.
- `webauth`: `redirectMap()` indexes canonical + extra redirect URLs by
  lowercased host; `redirectFor(host)` looks up the request host.
  - `canonicalLoginURL` now only bounces hosts with **no** registered redirect
    URL (preserving the 2026-07-17 fix for homelab DNS hosts).
  - `handleLogin` picks the per-host redirect URI, pins it into the sealed
    `flowState` (new `RedirectURL` field, `json:"u,omitempty"`), and overrides
    `redirect_uri` on the authorize URL.
  - `handleCallback` repeats the pinned `redirect_uri` on the token exchange
    (OAuth requires the exact same value); flows sealed before this change
    carry none and fall back to the canonical URL — no mid-deploy breakage.
  - `handleLogout` → `postLogoutFor(r)`: the configured post-logout URL is
    re-hosted to the request's host when that host is registered, so logging
    out of cloud.* returns to cloud.*.

## Risk review

- **Open redirect?** No new surface: only hosts explicitly listed in config
  can keep a flow; everything else still canonicalizes. `sanitizeReturnTo`
  unchanged.
- **Session cookie scope:** per-host (unchanged); a login on cloud.* now mints
  the cookie on cloud.*, which is exactly the fix.
- **Zitadel enforcement:** every URL in `ExtraRedirectURLs` must be registered
  on the OIDC app — already true in `zitadel/marketplace.tf`
  (`${var.cloud_base_url}/ui/auth/callback` + post-logout), applied with this
  change.
- **Stale flow cookies across deploy:** empty `RedirectURL` falls back to the
  canonical URL — behaves exactly as before the change.

## Tests

- `TestLoginOnExtraHost`: login on cloud.* stays local, authorize URL carries
  the cloud `redirect_uri`, sealed flow pins it; unknown host still bounces.
- `TestPostLogoutFor`: marketplace/cloud/unknown host table.
- Full `scripts/ci/verify.sh` green (fmt, vet, golangci-lint, tests, contract
  guard).

## Deployment — state as of 2026-07-19 ~01:00 (⏳ two Farshid steps)

- ut-market-place merged, CI + UI E2E + ACR push green; the multi-host image
  deploys automatically. Inert until the env var below is set.
- **Zitadel apply BLOCKED for Claude** (identity-scope classifier). Everything
  is staged: `infra/unitill-infra/zitadel/apply-in-cluster.sh` runs the
  documented in-cluster Job; the **targeted plan was verified**: exactly
  `~ zitadel_application_oidc.marketplace_web` adding the cloud redirect +
  post-logout URIs, **0 to destroy**. Two gotchas found and guarded:
  - a full (untargeted) run without `TF_VAR_smtp_*` would **destroy the live
    Brevo SMTP provider** (count-gated resource) — script now refuses;
  - Claude's az user lacks Key Vault secrets-get, hence the targeted run.
  Morning command:
  `cd infra/unitill-infra/zitadel && export KUBECONFIG=~/.kube/homelab-config && export ARM_ACCESS_KEY="$(az storage account keys list -g uni-till-platform -n unitillinfra --query '[0].value' -o tsv)" && TARGET=zitadel_application_oidc.marketplace_web ./apply-in-cluster.sh apply`
- homelab-k8s env (`AUTH_WEBLOGIN_EXTRA_REDIRECT_URLS`) was merged then
  **deliberately reverted**: with the app multi-host-aware but the callback
  unregistered, cloud logins would hit a Zitadel "redirect not allowed" error
  — a regression vs. the current canonical bounce. Re-apply the revert
  (`git revert <revert-commit>` in homelab-k8s, or re-add the env block)
  right after the Zitadel apply.
