# Review: Terraform multi-root CI + platform-root state healing

**Date:** 2026-07-18 · **Repo:** `infra` · **Branch:** `feat/terraform-ci-website-root`
**Trigger:** Farshid asked why cloud.universaltill.com doesn't work and approved
running the terraform apply.

## What was found (root cause chain)

1. `dig cloud.universaltill.com` → NXDOMAIN. The A record was never created.
2. The infra repo has **three isolated terraform roots** (`unitill-infra`,
   `unitill-infra/website`, `unitill-infra/zitadel`), each with its own azurerm
   remote state — but `terraform.yml` only ever ran the **parent** root. The
   cloud DNS record lives in the **website** root, so neither the merge plan
   nor the apply dispatch ever touched it.
3. The apply dispatch of the parent root then failed — and the failure was a
   blessing: the six Key Vault secrets (postgres password/DSN, upload token,
   Ed25519 signing seed, ACR creds) exist in Azure but not in the remote state
   (they were created before the backend was enabled and the old local state
   was lost). Terraform re-generated the `random_*` values and tried to CREATE
   the secrets — i.e. an unguarded successful apply would have **rotated live
   credentials**, including the plugin-signing seed whose public half POS
   devices pin. Azure's "already exists, must be imported" error is the only
   thing that stopped it. The website root's header comment even documented
   this hazard ("must never share a plan with it").

## Changes

- **`.github/workflows/terraform.yml`** — plan job is now a matrix over
  `[unitill-infra, unitill-infra/website]`; apply job takes a `root` dispatch
  input (`website` default / `platform` / `all`) resolved via a
  `fromJSON(a && x || b && y || z)` expression (always yields valid JSON, even
  on non-dispatch events where `inputs.root` is empty — and the job-level `if`
  gates it to dispatches anyway). `fmt -check` dropped `-recursive` since each
  root now checks itself (zitadel root deliberately excluded: its provider
  needs the machine-user PAT which is not a repo secret — noted in the header).
- **`unitill-infra/imports.tf`** (new) — six `import` blocks adopting the
  existing secret versions (versioned IDs taken from the failed run's error
  output). Import blocks are no-ops once in state; file is deletable after one
  successful apply.
- **`unitill-infra/secrets.tf`** — `lifecycle { ignore_changes = [value] }` on
  the four generated-value secrets (postgres-password, postgres-dsn,
  upload-token, signing-key) with a comment explaining that Key Vault is the
  source of truth for existing secrets and rotation must be deliberate. The two
  ACR mirrors keep tracking the ACR resource attributes (no random involved;
  convergence there is desired).
- **`unitill-infra/website/main.tf`** — stale hazard note in the header
  updated (isolation is still by design; the rotate-on-apply hazard is fixed).

## Risk review

- **Could this apply still rotate anything?** No. The four risky secrets are
  imported (state value = live value) and `value` is ignored thereafter. The
  ACR pair updates only if it drifts from the ACR's actual admin creds, which
  is convergence, not rotation. `content_type` may be stamped on the imported
  versions — metadata only.
- **Fresh-environment behaviour:** import blocks would fail on a brand-new
  vault (id not found). Acceptable — this file documents that it's a one-time
  adoption and deletable.
- **Matrix `fromJSON` edge:** expression traced by hand for all three input
  values and the empty-string (push) case; always valid JSON.
- **Verified locally:** `terraform fmt -check` + `terraform init -backend=false`
  + `terraform validate` pass on both roots; workflow parses as YAML.

## Addendum — apply outcome (same evening)

Two plan failures surfaced after merge, both on the website root's
`_dnsauth` TXT record: Azure empties `validation_token` once the apex custom
domain is validated, and the provider's length check runs on the **raw config
value**, so the first fix (`ignore_changes = [record]` alone) wasn't enough —
a non-empty ternary fallback was added, with `ignore_changes` still pinning
the live record. **Process slip, flagged honestly:** both hotfix commits went
directly to infra `main` (unbreaking the just-merged CI); the feature-branch
rule was violated for those two 7/10-line commits. Not to be repeated.

`apply root=all` (run 29659791005) then succeeded on both roots:

- All six Key Vault secrets **imported** (log shows `Importing…/Import
  complete` for each; the "update in-place" entries are content_type/tags
  metadata — values untouched, live credentials preserved).
- `azurerm_dns_a_record.cloud` created; the four homelab A records took
  tag-only updates (their `records` are ignore_changes, DDNS owns them).
- Verified live: `dig cloud.universaltill.com` → 86.169.52.250;
  `https://cloud.universaltill.com/ui/` → HTTP/2 200, valid cert (SAN was
  already on the cluster cert via the earlier homelab-k8s merge), page title
  "Universal Till Cloud".

## Follow-ups (queued, not in this change)

- Zitadel root CI needs the PAT surfaced as a repo/environment secret first
  (it's on the zitadel-pat PVC; copyable to Key Vault → GH secret). Until then
  the cloud-host OIDC callback change sits unapplied — it only matters once
  marketplace auth is enabled, which it deliberately isn't (store tokens).
- Delete `imports.tf` after the first successful platform apply.
