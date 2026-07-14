# Marketplace publishing QA (proposal — G20)

Status: **backlog proposal — 2026-07-14** (Farshid: "when a plugin deploys
to the market, it should test and then approve by Universal Till and then
be available").

## Honest current state

- Plugin repo CI packages, signs and uploads; **`AUTO_APPROVE=true`** in our
  own repos' pipelines approves instantly — fine for first-party dev, wrong
  for third parties.
- Manual review workflow exists server-side (assign + decision endpoints;
  approved → sign + approve; verified live 2026-07-06) but the admin
  `review_queue.html` is still **mock data**, and nothing runs the plugin
  before a human sees it.

## Target pipeline (every submission, including version updates)

1. **Submit** — developer's CI uploads the bundle (existing path).
2. **Automated gates** (marketplace-side, must all pass before a human
   spends time):
   - manifest schema + canonical-type taxonomy validation (exists at parse,
     move it to submission time);
   - signature/checksum + bundle hygiene (no symlinks/oversize/junk);
   - **permission lint**: `net:<host>` list is explicit, no wildcard hosts,
     flags dangerous combinations for the reviewer;
   - **sandbox smoke run**: instantiate the wasm module against synthetic
     events (the runtime + host functions make this cheap) — must not
     crash, must not call undeclared capabilities;
   - install E2E on a headless POS in CI (install → enable → menu/entries
     render → disable → uninstall clean).
3. **Human review by Universal Till** — real review queue UI (replace the
   mock): diff vs previous version, automated-gate results, permission
   changes highlighted. Reviewer role comes from Universal Till ID (G21).
4. **Approve → sign → publish** — existing signing path unchanged
   (ADR-0006 trust chain). Reject → developer notified with reasons.
5. `AUTO_APPROVE` survives only as a **first-party fast lane** restricted
   to the `universaltill` org; third-party submissions always pass 2–4.

## Fit

- Trust tiers (untrusted/trusted/system) already exist; QA outcome feeds
  the tier shown at install.
- Revocation path already exists for post-publish problems.
- Update reviews can be lighter when the permission set didn't change
  (fast-track re-approval).
