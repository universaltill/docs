# Plugin Release Artifact

Goal: define the canonical artifact that plugin repos produce for marketplace upload.

## Purpose

The plugin release artifact is the packaged unit a plugin repo publishes to the marketplace. It is not the same as an offline merchant bundle.

This contract exists so that:

- plugin repos package releases consistently
- marketplace upload and validation can rely on a stable structure
- till install flows consume marketplace-governed artifacts instead of raw source trees

## Artifact Types And Ownership

### Release Artifact

Produced by: plugin repo or plugin CI pipeline

Used for:

- marketplace upload
- marketplace validation and review
- marketplace-hosted distribution to tills

Examples:

- `com.universaltill.ut-faq_0.1.2_linux_amd64.tar.gz`
- `com.universaltill.ut-faq_0.1.2_linux_arm64.tar.gz`
- `com.universaltill.ut-faq_0.1.2_universal.tar.gz`

### Offline Merchant Bundle

Produced by: marketplace

Used for:

- disconnected store export/import workflows
- multi-plugin merchant-scoped delivery packages

Notes:

- marketplace generates these from approved release artifacts
- plugin repos do not publish merchant bundles directly

## Canonical Archive Format

- Format: `.tar.gz`
- One archive per target OS/architecture unless the plugin is explicitly architecture-independent
- Archive checksum is calculated over the final `.tar.gz` file

## Artifact Naming Convention

Preferred format:

- `<plugin-id>_<version>_<os>_<arch>.tar.gz`

Examples:

- `com.universaltill.ut-faq_0.1.2_linux_amd64.tar.gz`
- `com.universaltill.ut-faq_0.1.2_linux_arm64.tar.gz`

For architecture-independent packages, use:

- `<plugin-id>_<version>_universal.tar.gz`

Do not omit the architecture marker by implication.

## Required Archive Contents

Required files and directories:

- `manifest.json`
- `bin/<plugin-runtime-payload>` or equivalent runtime directory
- `assets/`
- plugin content or static resources required at runtime
- `README.md`
- `CHANGELOG.md`
- `LICENSE`
- `release.json`

Notes:

- Paths referenced in `manifest.json` must resolve inside the archive.
- The packaged content must include all files needed for offline operation after install.

## Optional Archive Contents

- `signature.sig`
- `sbom.spdx.json`
- `checksums.txt`

These are not required for MVP packaging, but the structure reserves them now so later trust-tier hardening does not require a format reset.

## `release.json`

`release.json` provides packaging metadata about the produced archive.

Recommended fields:

- `plugin_id`
- `version`
- `build_time`
- `target_os`
- `target_arch`
- `artifact_name`
- `artifact_sha256`
- `git_sha` when available

This metadata supports auditability and future CI-based publishing.

## Integrity Model

### Checksum

- The canonical checksum is the SHA-256 of the final archive file.
- Marketplace should compute and store this checksum during upload.
- A client-provided checksum may be supplied and compared during ingestion.

### Signature

- Detached signatures are optional for MVP.
- If present, the signature should apply to the final archive checksum.
- Marketplace should preserve submitted signature metadata even if full trust-chain enforcement is deferred.

### SBOM

- SBOM is optional for MVP.
- Preferred future format: SPDX JSON.

## Relationship To `manifest.json`

`manifest.json` is the runtime and compatibility contract for the plugin. The release artifact wraps that manifest together with the files the manifest references.

Working rules:

- `entrypoints` remain part of the platform contract and should be documented as required unless the platform contract is explicitly changed.
- `resources` paths in the manifest must point to files included inside the archive.
- Version values should align between the manifest and the uploaded release metadata.

See also: [Plugin Manifest](/Users/farshid/repos/unitill/docs/docs/plugins/manifest.md)

## FAQ Plugin Worked Example

Expected artifact name:

- `com.universaltill.ut-faq_0.1.2_linux_amd64.tar.gz`

Expected archive layout:

```text
com.universaltill.ut-faq_0.1.2_linux_amd64.tar.gz
├── manifest.json
├── bin/
│   └── ut-faq
├── assets/
│   ├── icon.png
│   ├── screenshot-en.png
│   └── screenshot-fr.png
├── content/
│   ├── en-US.json
│   ├── en-GB.json
│   └── ...
├── README.md
├── CHANGELOG.md
├── LICENSE
└── release.json
```

This example is the reference target for the first FAQ packaging story.

## Publish And Install Boundary

Publish/upload flow:

1. Plugin repo builds release artifact
2. Plugin repo or CI uploads release artifact to marketplace
3. Marketplace validates, stores, and governs the release

Install/export/import flow:

1. Marketplace exposes approved releases for install
2. Till installs approved marketplace artifacts
3. Marketplace may also export merchant-scoped offline bundles for disconnected environments

These flows must stay distinct in docs, tooling, and storage.

## Open Decisions / Current Limitations

- Whether all plugin types will always ship a `bin/` payload or whether some UI-only packages can standardize a different runtime layout
- When detached signatures become mandatory by trust tier
- When SBOM becomes required for approved or verified releases

## Sources

- `ut-plugin-faq/specs/001-multilingual-faq-page/contracts/manifest.md`
- `ut-market-place/internal/downloads/ingest.go`
- `ut-market-place/internal/downloads/manual_export.go`
- `docs/plugins/manifest.md`
- `docs/marketplace/cli.md`
