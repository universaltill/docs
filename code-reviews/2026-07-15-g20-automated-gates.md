# Code review — G20 increment 1: marketplace automated release gates

Date: 2026-07-15 · Repo: ut-market-place · Branch: feat/g20-automated-gates
Spec: docs/architecture/marketplace-qa-pipeline.md (updated same session)

## What shipped

Every uploaded release now passes **seven automated gates** before it can
be approved (synchronously at upload, persisted to `scan_results.checks`;
`ErrNotReviewReady` blocks approval on BOTH the direct and review-decision
paths when any gate fails):

1. `manifest_valid` (existing) — schema + release-version match.
2. `checksum_verified` (existing) — stored bytes hash to the recorded sum.
3. `bundle_hygiene` (new, `internal/downloads/bundlecheck.go`) — tar.gz
   only; no path traversal/absolute paths, no links or device nodes, no
   junk (`.git/`, `node_modules/`, `.DS_Store`, macOS AppleDouble `._*`),
   compressed ≤64 MiB / uncompressed ≤256 MiB / ≤4096 entries. One pass
   also lifts `manifest.json` + `bin/*.wasm` so the artifact is read once.
4. `manifest_matches_bundle` (new) — uploaded metadata must parse equal to
   the bundle's own `manifest.json` (a mismatch previously let catalog
   metadata diverge from what the POS would verify and run).
5. `permission_lint` (new, `permlint.go`) — `net:<host>` grants must name
   one bare host: wildcards/ports/paths fail; raw-IP or `.local`/`.lan`
   hosts and the storage+net combination become **reviewer flags**
   (`scan_results.lint_flags`), not failures.
6. `wasm_smoke` (new, `wasmsmoke.go`) — the module is compiled and run the
   way the POS runs it (wazero 1.12.0 matching the POS, WASI command,
   synthetic `qa.smoke` event on stdin, 64 MiB memory cap, 5 s deadline)
   against a **stub `ut` host module that mirrors the POS ABI and records
   calls**. Fails on: not compiling, imports outside
   {WASI, ut.log_write/storage_get/storage_set/http_request}, traps,
   hangs, or a **call** to a capability the manifest doesn't declare.
   A capability *import* without permission and a nonzero exit only flag
   (dead code / unhandled event type are legitimate). `http_request`
   always returns denied — sandbox code never touches the network.
   Runtime `none` passes with a flag if wasm ships anyway.
7. `artifact_exists` (existing).

**First-party fast lane:** `POST /api/admin/releases/{id}/approve` (direct
approval, used by our repos' AUTO_APPROVE) now refuses listings whose slug
doesn't match `MARKETPLACE_FIRST_PARTY_PREFIXES` (default
`com.universaltill.`) with 422 + guidance to use assign + review-decision.
Gatekeeper (`ValidateRelease`) requires all new checks — releases scanned
before this change need re-validation to re-qualify.

**Reviewer queue** (`/ui/admin/reviews`): each row now shows a gates pill
(✓ / ✗ with failing check names), reviewer flags (⚑), and added
permissions vs the previous release — the data reviewers need without
leaving the queue.

**Honest limit (documented in the spec):** with today's single shared
admin bearer, a third party holding the upload token could still
self-assign + self-approve. Reviewer identity is G21; provider
registration is G26. The gates bind regardless of who approves.

## E2E (local marketplace, real plugin)

Fresh marketplace (SQLite + file blob + signing key): uploaded the REAL
`ut-plugin-payment-demo` v1.1.0 bundle → all seven gates passed; the smoke
run executed the actual TinyGo-built module, which called `log_write` and
`storage_set` (recorded, permitted by its `storage` grant) and exited 0.
Direct approve succeeded (first-party slug) and signed the bundle.
A hostile bundle (junk file + `net:*` + wasm runtime with no module)
failed with all three problems reported. A clean third-party bundle
passed the gates but direct approve returned 422; assign + review-decision
approved it, and the queue UI rendered the gates pill and the
storage+net reviewer flag.

Found in E2E: macOS `tar` ships AppleDouble `._*` files —
`bin/._plugin.wasm` shadowed the real module and failed the smoke compile.
Fixed both sides: hygiene now rejects `._*` as junk, and payment-demo's
`package.sh` sets `COPYFILE_DISABLE=1` (other plugin repos when next
touched; CI Linux builds were never affected).

## Review findings (multi-agent review) and outcomes

**Fixed before merge:**
1. **Oversize uploads stored but permanently unscannable** — no request
   cap at ingest, while the scanner refuses >64 MiB artifacts: a large
   upload succeeded, then failed every scan with a confusing checksum-ish
   message (and unbounded bodies could DoS disk/blob). Fixed:
   `http.MaxBytesReader` caps the upload request at 64 MiB + form
   allowance with a clear message.
2. **Per-entry RAM blowup in bundle inspection** — a kept entry buffered
   up to the full 256 MiB budget before the 64 MiB per-module check ran.
   Fixed: kept entries stream through their own cap (+1) and are rejected
   without buffering beyond it (manifest capped at 1 MiB).
3. **`manifest_matches_bundle` only compared the 8 parsed fields** — a
   bundle manifest could diverge from the reviewed metadata in any field
   `manifest.Parse` doesn't model (entries, executable, …). Fixed: the
   gate now compares both documents as canonical JSON, so every field
   counts. (Publishers upload the identical file, so no false positives;
   E2E re-verified with the real payment-demo bundle.)
4. **ABI signature drift produced an opaque failure** — the import audit
   checked names only; a signature mismatch surfaced as "crashed on the
   synthetic event" at link time. Fixed: the audit now validates each
   `ut.*` import's wasm signature against the ABI table and reports it
   plainly.
5. Cleanup: `scanProblems` now reuses the `stringSlice` coercion helper.

**Known/accepted (documented):**
- `Gatekeeper.ValidateRelease` requires the new checks, so releases
  scanned pre-G20 read as "blocked" there while `ApproveRelease` still
  gates on `scan_status` alone — consistent for everything scanned from
  now on; a re-validate endpoint for old releases is a follow-up.
- The smoke run builds a fresh wazero runtime per module (bundles ship
  one module today) and direct-approve does three DB reads (rare admin
  op) — measure before optimizing.
- Queue UI shows raw check names while the gatekeeper emits `*_failed`
  codes; both derive from the same persisted checks map.
- The `ut` ABI stub must stay hand-synced with
  `universal-till/internal/plugins/wasm_hostfns.go` (noted in both files).
- Full upload rate-limiting/concurrency bounds are infra work beyond the
  size cap added here.

## Tests

`internal/downloads/gates_test.go`: hygiene table tests (traversal,
symlink, junk dir/file), clean-bundle extraction, missing manifest;
permission lint table tests; wasm smoke against **handcrafted wasm
binaries** (no toolchain in CI): noop passes, trap fails, unknown import
module fails, undeclared capability call fails, declared capability call
passes and is recorded, garbage fails compile; scanner-level: clean wasm
release passes all gates, manifest mismatch fails, wasm-runtime-without-
module fails. Existing scanner/gatekeeper/api tests updated (real tar.gz
fixtures, stub approver grew FastLaneAllowed, third-party direct-approve
422 test). `scripts/ci/verify.sh` green.

## Follow-ups

- Install E2E on a headless POS in marketplace CI (G20 remaining).
- Reviewer identity + roles (G21); provider registration (G26).
- Re-validate endpoint for releases scanned before the new gates.
- COPYFILE_DISABLE in the other plugin repos' package.sh.
