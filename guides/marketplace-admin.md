# Using the Marketplace (Vendor & Admin)

The marketplace (`ut-market-place`) is where plugin releases are uploaded,
reviewed, signed, and made available to stores. The web UI is served under `/ui/`.

Live instance: **`https://marketplace.home.taskrunnertech.co.uk`**.

## Roles

- **Vendor** — a plugin author. Uploads releases for their listing.
- **Admin/operator** — reviews releases, approves (which signs them), and manages
  which stores are entitled to which plugins.

## Vendor: publishing a release

Vendors normally publish from their plugin repo with `scripts/publish.sh` (see
[`../for-plugin-developers.md`](../for-plugin-developers.md)). Under the hood this
POSTs the artifact + manifest + checksum + release notes to
`/ui/api/vendor/releases/upload` with an upload token.

On upload the marketplace:

- validates the manifest,
- computes the SHA-256 and verifies it against the vendor-supplied checksum
  (deleting the blob if it doesn't match),
- persists a **`PluginRelease`** and, on first publish for a plugin, auto-creates a
  **draft `PluginListing`**,
- runs a structural scan. When `scan_status=passed`, the release is review-ready.

The upload UI at `/ui/…/upload` accepts the same submission from a browser and
shows the JSON result.

## Admin: reviewing & approving

1. Open the review queue. Review-ready releases (scan passed, manifest valid,
   checksum verified) are eligible to approve.
2. Inspect the manifest, scan results, and the permission/capability delta versus
   the previous release of the same listing.
3. **Approve.** Approval:
   - signs the canonical manifest with the marketplace **Ed25519** signing key,
   - repackages the bundle so its `manifest.json` carries the `signature`,
   - marks the release `approved` and available for entitled stores.

The signing key is provided via `MARKETPLACE_SIGNING_KEY` (in production, from
Azure Key Vault). The corresponding public key is served at
`/ui/api/signing-key` and must be configured on every till.

## Admin: entitlements

A store only sees/installs plugins it is entitled to. Entitlements link a
merchant/store to a listing. Without an entitlement the till's download-token
request returns **not entitled**.

## Install visibility

Tills report install progress back via `/ui/api/installs/{id}/state`, so an
operator can see whether a given store's install is active/failed. The
`mp-cli` tool can create install intents and query status from the command line.

## Configuration recap

| Concern | Where |
|---|---|
| Upload/admin auth | `MARKETPLACE_UPLOAD_TOKEN` |
| Signing key | `MARKETPLACE_SIGNING_KEY` (Key Vault in prod) |
| Database | `DATABASE_DRIVER` + `POSTGRES_DSN` (Postgres in prod, in-cluster) |
| Artifact storage | `BLOB_BUCKET_URL` (`file://` on a PVC in prod) |

Deployment details: [`../reference/deployment.md`](../reference/deployment.md).
