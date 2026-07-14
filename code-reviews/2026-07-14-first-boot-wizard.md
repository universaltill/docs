# Review: first-boot setup wizard (zero-touch phase B) + infra CI wiring

**Date:** 2026-07-14 · **Repos:** universal-till (main), infra · **Author/Reviewer:** Claude (self-review before commit)

Spec: docs/architecture/zero-touch-setup.md, phase B.

## What shipped — universal-till

- **`/setup` wizard** (auth-exempt alongside /login; both routes refuse once
  an operator exists): language (locale links, live switch incl. RTL) →
  country (14 entries prefill currency/tax/inclusive via data attributes;
  "Other" keeps defaults; everything editable in Settings later) → shop name
  → admin PIN → done. Alpine steps + progress dots, standalone page like
  login.html, big touch targets, 28 keys en+fa.
- **`POST /api/setup`** applies state exactly like /api/settings/save
  (UpdateState → SaveState → InitCurrency → engine rebuild), saves
  `store.name` + `setup.completed`, then reuses the first-boot admin
  semantics (ensureFirstBootAdmin + SetUserPIN + session + audit
  `first_boot_setup` with via=wizard). Currency input validated against the
  registry; tax bounded 0–100.
- `GET /login` on first boot now redirects to /setup; the bare
  `POST /api/auth/setup` stays as fallback. `setSessionCookie` hoisted from a
  closure to package level for reuse.

Verified live on a fresh DB: / → /login → /setup; wizard renders (en + fa);
full POST (IR/IRT/10%/Farsi shop name/PIN) → session live, sale screen serves
`data-currency="IRT"`, settings persisted, /setup refuses afterwards, PIN
mismatch re-renders pre-completion. Unit test updated for the new redirect +
wizard render; full suite + both guards green.

## Findings / notes

1. **Pre-existing (not fixed here):** settings carry BOTH `pos.tax_inclusive`
   and `store.tax_inclusive`; SaveState writes the latter, seed writes the
   former. State loads correctly, but the duplication is a cleanup candidate.
2. Step 5 "join existing shop" fork intentionally deferred to phase D
   (multi-till pairing) — not rendered yet rather than greyed out.

## Also this session — infra repo CI is real now

- infra pushed to **universaltill/infra** (private; main default;
  feature/keyvault-secrets merged with the ROTATION WARNING preserved).
- OIDC wired: federated credentials `gh-infra-main`/`gh-infra-pr` on the
  existing unitill-gh-oidc app; AZURE_* repo secrets set; SP granted
  Contributor on RG uni-till-platform (backend state needs listKeys; apply
  needs it anyway) + Reader on RG DNS (plan reads the taskrunnertech.co.uk
  zone). **terraform plan job green**; apply remains manually gated.
- tfplan file (can embed secrets) was briefly committed locally → removed and
  gitignored before push.
