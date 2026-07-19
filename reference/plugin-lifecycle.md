# Plugin Lifecycle

The end-to-end lifecycle of a Universal Till plugin across the three repos:
`ut-plugin-faq` (a plugin), `ut-cloud` (the marketplace, renamed from
`ut-market-place` 2026-07-19), and
`universal-till` (the POS host). This reflects the **implemented** contract
(Epic 6), not a proposal.

See also: [Plugin Manifest](./manifest.md) · [Release Artifact](./release-artifact.md)

## Stages

```
 publish                 validate + sign            install
 (plugin repo)           (marketplace)              (POS host)
 ┌──────────┐  upload    ┌──────────────────────┐   token   ┌──────────────┐
 │ package  ├──────────► │ ingest → scan →       ├─────────► │ download →   │
 │ artifact │            │ approve+sign (Ed25519)│  bundle   │ verify → run │
 └──────────┘            └──────────────────────┘           └──────────────┘
```

### 1. Publish (plugin repo → marketplace)

`scripts/package.sh` builds the canonical release artifact
(`<plugin-id>_<version>_<os>_<arch>.tar.gz` with `manifest.json` at the root — see
[Release Artifact](./release-artifact.md)). `scripts/publish.sh` uploads it to
`POST /ui/api/vendor/releases/upload` with the artifact, manifest, `plugin_id`,
`version`, `channel`, and `expected_hash`. CI (`.github/workflows/release.yml`)
runs the same scripts on `v*` tags.

### 2. Validate (marketplace, at upload)

The marketplace validates the manifest **before** storing any bytes
(`pkg/manifest` — required fields, semver, lowercase reverse-DNS id, ≥1 permission
and locale, version alignment), computes a server-side SHA-256, verifies the
client `expected_hash`, and persists a `PluginRelease` (auto-creating a draft
`PluginListing` on first publish). A failure returns HTTP 422 and stores nothing.

### 3. Structural scan (marketplace, synchronous)

Immediately after ingest, a structural validation pass re-checks the manifest,
confirms the stored artifact exists and re-hashes to the recorded checksum, and
records an informational permission/capability diff vs the listing's previous
release. Result → `scan_status` (`pending` → `validating` → `passed`|`failed`) +
`scan_results`. A release is **review-ready** only when `scan_status=passed`.

### 4. Review + approval + signing (marketplace)

A reviewer is assigned (`POST /ui/api/admin/releases/{id}/assign-review`) and
submits a decision (`…/review-decision`): **approved** signs the release and flips
it to `approved`; **rejected** marks it rejected; **needs_revision** leaves it for
the vendor. Approval (`internal/reviews/approver.go`):
- signs the canonical manifest with the marketplace **Ed25519** key,
- repackages the bundle so its `manifest.json` carries the `signature`,
- stores the signed bundle and records `signature` + the signed-bundle checksum,
- sets `status=approved`, `approved_at`.

The public key is published at `GET /ui/api/signing-key` for POS configuration.

### 5. Delivery (marketplace → POS)

The POS requests a download token (`IssueDownloadToken`). The marketplace serves
it only for an **approved** release with a non-empty signature
(`downloadsvc validateReleaseEntity`), returning `BundleURL`, `ChecksumSHA256`,
and `Signature`.

### 6. Apply (POS host)

`universal-till/internal/plugins/installer_marketplace.go`:
download the bundle → verify the bundle SHA-256 → extract → verify the manifest's
**Ed25519 signature** against `cfg.Marketplace.PublicKey` → check
`signature == token.Signature` → verify compatibility (`device_arch`,
`min_pos_version`) and the executable bit → install and register the plugin's
`entries` (e.g. the FAQ page under Help/Support).

## Install states + telemetry

Standard states the POS host reports back:

```
requested → downloading → installing → active
                                     ↘ failed (error details)
active → disabled → uninstalled
active → (update) → downloading → …
```

Telemetry/status payload fields: `pos_id`, `merchant_id`, `plugin_id`, `version`,
`state`, `error` (on failure), `timestamp`. The marketplace release carries its
own coarse status (`uploaded` → `approved`/`rejected`) and `scan_status`.

> **Current implementation note:** the marketplace-side publish→sign→approve→
> download path and the POS verify/install path are implemented and verified
> (cross-repo signature test + live deploy). The CLI-driven *install-intent*
> tracking and POS→marketplace *status reporting* API (story 1-1) are not yet
> built — install state is currently observed at the POS, not aggregated in the
> marketplace.

## Offline / disconnected operation

- The release artifact is a self-contained `.tar.gz`; a signed bundle can be
  exported and side-loaded to a disconnected till (the POS still verifies the
  Ed25519 signature offline against its configured public key).
- The POS host should cache bundles and retry install/reporting when back online.
- Checkout must never be network-blocked by plugin delivery.

## Update / remove

- **Update:** publish a new version → review/approve/sign → the POS installs the
  new signed bundle. Release uniqueness is per listing (`(listing, version,
  channel)`), so channels (`stable`/`beta`/`alpha`) allow staged rollout.
- **Remove:** disable/uninstall at the POS host; revocation on the marketplace
  side (revoked releases fail the download-token gate).

## Compatibility + validation error surfaces

- Compatibility is enforced at apply time via `device_arch` (`any` or `os/arch`)
  and `min_pos_version`.
- Validation errors surface consistently as the `{error:{message,details}}`
  shape (upload/API), the scanner's `scan_results.problems`, and the POS
  installer's verification errors. The authoritative catalog is
  `ut-cloud/docs/manifest-validation-errors.md`.
