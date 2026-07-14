# Marketplace publishing QA (G20)

Status: **increment 1 SHIPPED 2026-07-15** (automated gates + first-party
fast lane + gate-aware review queue; review record
`code-reviews/2026-07-15-g20-automated-gates.md`). Remaining: install E2E
in CI, reviewer identity via Universal Till ID (G21), provider
registration (G26).

## Current state (after increment 1)

- Every upload is scanned synchronously with **seven gates**: manifest
  validation, artifact checksum, **bundle hygiene** (tar.gz only, no
  traversal/links/junk/AppleDouble, size caps), **manifest-matches-bundle**
  (uploaded metadata must equal the bundle's `manifest.json`),
  **permission lint** (`net:<host>` explicit, no wildcards; reviewer
  flags for storage+net combos, raw-IP/LAN hosts), and a **wasm sandbox
  smoke run** — the module is compiled and instantiated exactly as the POS
  runs it (wazero, WASI command, synthetic `qa.smoke` event on stdin,
  stubbed `ut` host module that records calls), failing on unknown
  imports, traps, hangs, or calls to undeclared capabilities. Runtime
  `none` bundles skip the smoke with a flag if they ship wasm anyway.
- Failed gates block approval on **both** paths (`ErrNotReviewReady`):
  direct approve and review-decision.
- The reviewer queue (`/ui/admin/reviews`) is real and now shows each
  release's gate outcome, reviewer flags, and permission deltas inline.
- **Direct approve is first-party only**: listings whose slug matches
  `MARKETPLACE_FIRST_PARTY_PREFIXES` (default `com.universaltill.`);
  everything else must go through assign + review-decision.
- **Honest limit:** with today's single admin bearer, a third party who
  held the upload token could still self-assign and self-approve. Real
  reviewer identity/role separation arrives with Universal Till ID (G21)
  and provider registration (G26); the gates above bind regardless.
- Plugin `package.sh` scripts must set `COPYFILE_DISABLE=1` (macOS tar
  ships `._*` AppleDouble junk otherwise — the hygiene gate rejects it;
  payment-demo's script fixed 2026-07-15, other plugin repos when next
  touched).

## Target pipeline (every submission, including version updates)

1. **Submit** — developer's CI uploads the bundle (existing path). ✅
2. **Automated gates** (marketplace-side, must all pass before a human
   spends time):
   - manifest schema + canonical-type taxonomy validation ✅ (at scan);
   - signature/checksum + bundle hygiene (no symlinks/oversize/junk) ✅;
   - **permission lint**: `net:<host>` list is explicit, no wildcard hosts,
     flags dangerous combinations for the reviewer ✅;
   - **sandbox smoke run**: instantiate the wasm module against synthetic
     events (the runtime + host functions make this cheap) — must not
     crash, must not call undeclared capabilities ✅;
   - install E2E on a headless POS in CI (install → enable → menu/entries
     render → disable → uninstall clean) — **remaining**.
3. **Human review by Universal Till** — real review queue UI with
   automated-gate results and permission changes highlighted ✅; diff vs
   previous version rendering and reviewer role from Universal Till ID
   (G21) — **remaining**.
4. **Approve → sign → publish** — existing signing path unchanged
   (ADR-0006 trust chain). ✅ Reject → developer notified with reasons
   (response body today; email/portal notification with G26).
5. `AUTO_APPROVE` survives only as a **first-party fast lane** ✅ for
   direct approve (slug prefixes via `MARKETPLACE_FIRST_PARTY_PREFIXES`);
   full enforcement across the review path needs G21 identity.

## Fit

- Trust tiers (untrusted/trusted/system) already exist; QA outcome feeds
  the tier shown at install.
- Revocation path already exists for post-publish problems.
- Update reviews can be lighter when the permission set didn't change
  (fast-track re-approval).
