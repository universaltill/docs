# Story 6-6 — End-to-End FAQ Plugin Install Validation (Report)

Date: 2026-07-06
Author: Claude (autonomous)

## Objective

Exercise the full chain: package the FAQ plugin → publish to the marketplace →
verify stored state → install on a till. Report exactly what works and, where it
does not, the precise failing boundary (no faked success).

## Environment

- Marketplace built from `ut-market-place@606b30c` (post 6-4), run locally:
  - `DATABASE_DRIVER=sqlite`, `SQLITE_PATH=<scratch>/data/marketplace.db`
  - `BLOB_BUCKET_URL=file://<scratch>/blob?create_dir=true`
  - `MARKETPLACE_HTTP_ADDRESS=:8081`, TLS off, no upload token (open, dev)
- Plugin artifact: `ut-plugin-faq@16195de`, packaged via `scripts/package.sh`
  → `dist/com.universaltill.ut-faq_0.1.2_darwin_arm64.tar.gz`
  (sha256 `a34c3439…97a4`, 946 441 bytes).
- Publish via `ut-plugin-faq/scripts/publish.sh`
  (`MARKETPLACE_BASE_URL=http://localhost:8081`).

## Result summary

| Stage | Outcome |
|-------|---------|
| Package artifact | ✅ works |
| Upload to marketplace (`/ui/api/vendor/releases/upload`) | ✅ HTTP 201 |
| Manifest validation (ingest) | ✅ passed |
| Blob storage + SHA-256 verification | ✅ stored, checksum matched |
| Auto-create draft listing | ✅ created |
| Synchronous structural validation (6-4) | ✅ `scan_status=passed` |
| **Till install from `universal-till`** | ❌ **blocked — two boundaries (below)** |

## Publish half — full success (evidence)

`publish.sh` returned HTTP 201 with:

```json
{"data":{"release_id":"d71e2e9d-…","listing_id":"efda7b78-…",
"plugin_id":"com.universaltill.ut-faq","version":"0.1.2","channel":"stable",
"artifact_checksum":"a34c3439…97a4","status":"uploaded","scan_status":"passed",
"next_steps":["Structural validation passed","Submit the release for manual review"]}}
```

Persisted state verified directly:

- **Blob:** `releases/efda7b78-…/0.1.2/d71e2e9d-….tar.gz` (946 441 bytes) on disk.
- **Release row:** `version=0.1.2, channel=stable, status=uploaded,
  scan_status=passed, artifact_checksum=a34c3439…97a4`.
- **Listing row:** `slug=com.universaltill.ut-faq, display_name="Universal Till FAQ",
  plugin_type=page, vendor_name=unassigned, trust_tier=unverified`.

## Install half — blocked (precise boundaries)

The POS marketplace install (`universal-till/internal/plugins/installer_marketplace.go`)
starts by calling the marketplace `IssueDownloadToken`, which requires the
release to satisfy `validateReleaseEntity`
(`ut-market-place/internal/api/downloadsvc/service.go:585`). Our release fails
two of its preconditions, so the install cannot even begin its download:

1. **Release is not `approved`.** `validateReleaseEntity` requires
   `release.Status == "approved"` and `ApprovedAt != nil`. Our release is
   `uploaded`. There is **no approval/review-submission path wired** — the review
   workflow (`internal/reviews/service.go`) is still stubbed (noted in the 6-4
   review). So no release can currently reach `approved`.

2. **No Ed25519 signature.** The same guard requires `release.Signature != ""`,
   and the POS then verifies an Ed25519 signature over the manifest against its
   configured `cfg.Marketplace.PublicKey`
   (`universal-till/internal/plugins/manifest_verifier.go`). The marketplace
   **never signs releases** — grep shows no Ed25519 signing anywhere (only ECDSA
   for TLS certs). Upload accepts an optional `signature` passthrough, which
   `publish.sh` does not send; the stored signature length is 0.

Both are confirmed against the live DB: `SELECT length(signature)` → `0`,
`status` → `uploaded`.

## What it would take to close the install gap

1. **Marketplace release signing.** Provision a marketplace Ed25519 keypair;
   sign the canonical manifest at approval time; store the signature on the
   release; expose the public key (e.g. `.well-known`) for POS configuration.
2. **Approval workflow.** Implement review submission → decision so a release can
   transition `uploaded → approved` with `approved_at` set (currently
   `internal/reviews/service.go` is a stub; the 6-4 gatekeeper only *reads*
   review state).
3. **POS configuration.** Set `cfg.Marketplace.PublicKey` to the marketplace's
   public key so `ManifestVerifier` can verify signatures.
4. Then re-run: `IssueDownloadToken` → download → verify → install.

## Conclusion

The **publish pipeline (stories 6-1 … 6-5) is end-to-end functional and verified**
against a running marketplace. Story 6-6's install leg was blocked by two design
gaps outside the 6-2…6-5 scope — now **closed** (see the addendum below).

---

## Addendum (2026-07-06) — install gaps closed

The two blockers above were implemented and verified:

- **GAP-1 signing + GAP-2 approval** (`ut-market-place`, commit `e523d0a`): the
  marketplace now signs a release's manifest with an Ed25519 key, repackages the
  bundle so its `manifest.json` carries the signature, and an approval step flips
  the release `uploaded → approved` (setting `approved_at`, signature, and the
  signed-bundle checksum). New endpoints: `POST /ui/api/admin/releases/{id}/approve`
  and `GET /ui/api/signing-key`. Key from `MARKETPLACE_SIGNING_KEY`.
- **GAP-3** (`ut-market-place`, commit `5fc6b09`): release uniqueness is now
  per-listing.
- **Cross-repo proof** (`universal-till`, commit `f4ca570`): a test using the
  **real POS `ManifestVerifier`** accepts a marketplace-signed fixture, guarding
  the canonical-JSON contract against struct drift.

**Live re-run** (marketplace with signing key, sqlite + file blob):
`publish.sh` → 201 (scan passed) → `POST …/approve` → `approved` with signature
`baa952cd…`; the stored signed bundle's SHA-256 (`72d3c99d…`) matches the recorded
checksum, and Ed25519 verification of its manifest (POS canonicalization) against
the public key from `/ui/api/signing-key` returns **true**. A till configured with
that public key would therefore accept and install the release.

**Remaining for a literal live till install (operational, not code):** run the POS
process pointed at the marketplace with `cfg.Marketplace.PublicKey` set to the
published key and real merchant/store/device IDs; the download-token → download →
verify → install path then exercises the deployed marketplace.
