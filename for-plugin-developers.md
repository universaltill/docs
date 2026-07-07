# Plugin Developer Guide

How to build a Universal Till plugin, publish it to the marketplace, and get it
onto tills. `ut-plugin-faq` is the reference implementation — copy its layout.

For the exact contracts referenced here, see:
[plugin manifest](reference/plugin-manifest.md) ·
[release artifact](reference/release-artifact.md) ·
[lifecycle](reference/plugin-lifecycle.md).

---

## 1. What a plugin is

A plugin is a self-contained bundle with a **`manifest.json`** and a compiled
executable, plus any assets/content. It declares a `canonical_type` (one of
`page`, `button`, `payment`, `report`, `integration`, `background_job`, `device`)
and one or more **`entries`** that tell the POS where the plugin surfaces (e.g. a
page under a menu group).

Minimal manifest (abridged — full field list in
[reference/plugin-manifest.md](reference/plugin-manifest.md)):

```json
{
  "id": "com.universaltill.ut-faq",
  "name": "Universal Till FAQ",
  "version": "0.1.2",
  "canonical_type": "page",
  "executable": "bin/ut-faq",
  "entrypoint": "./bin/ut-faq",
  "device_arch": "any",
  "min_pos_version": "1.0.0",
  "permissions": ["storage.local.10MB"],
  "locales": ["en-US", "fr-FR", "ar-SA"],
  "entries": [
    { "type": "page", "key": "faq-page", "label": "Help / FAQ",
      "route": "/plugin/faq", "menu_group": "help_support", "sort_order": 10 }
  ]
}
```

`manifest.json` is the source of truth; keep `package.json` `version` and the
`CHANGELOG.md` in sync.

## 2. Repo layout (from ut-plugin-faq)

```
src/manifest/manifest.json   # the manifest (source of truth)
src/…                        # the plugin runtime (compiled to bin/<name>)
content/<locale>.json        # localized content
assets/                      # icons, etc.
tools/pkgtool/               # stdlib validator + stage/release-json helper
scripts/validate.sh          # validate the manifest
scripts/package.sh           # build the release artifact
scripts/publish.sh           # upload to the marketplace
```

## 3. Validate, package, publish

```bash
# 1. Validate the manifest + version alignment
scripts/validate.sh

# 2. Package for a target (cross-compiles, stages, tars, checksums)
TARGET_OS=linux TARGET_ARCH=amd64 scripts/package.sh
#    → dist/<plugin-id>_<version>_<os>_<arch>.tar.gz (+ .sha256)

# 3. Publish to the marketplace
MARKETPLACE_BASE_URL=https://marketplace.home.taskrunnertech.co.uk \
MARKETPLACE_UPLOAD_TOKEN=<token> \
  scripts/publish.sh
```

`publish.sh` uploads the artifact + manifest + checksum + release notes (from the
`CHANGELOG.md` section) to `POST /ui/api/vendor/releases/upload`. On first publish
the marketplace auto-creates a **draft listing** for the plugin.

The marketplace validates the manifest, computes and verifies the SHA-256,
persists the release, and runs a structural scan. `scan_status=passed` means the
release is **review-ready**.

CI: `.github/workflows/release.yml` runs the same scripts on `v*` tags (the tag
must match the manifest version). It publishes a single architecture per release
(the marketplace stores one artifact per `(listing, version, channel)`).

## 4. Approval + signing (marketplace side)

An operator reviews and approves the release (see
[marketplace/admin guide](guides/marketplace-admin.md)). Approval:

- signs the canonical manifest with the marketplace **Ed25519** key,
- repackages the bundle so its `manifest.json` carries the `signature`,
- flips the release to `approved`.

**Important — the signing contract:** the signature is Ed25519 over the POS
`plugins.Manifest` struct's canonical JSON (with the signature field emptied).
The marketplace's `signing.CanonicalManifest` must mirror that struct
field-for-field; a cross-repo test guards this. If you change manifest fields,
keep both sides in lock-step.

## 5. Install on a POS

Once approved, a store that is entitled to the plugin can install it: the POS
requests a download token, downloads the signed bundle, verifies the Ed25519
signature against the marketplace public key, checks compatibility
(`device_arch`, `min_pos_version`) and the executable bit, then installs and
registers the plugin's `entries`. For the FAQ plugin this puts a **Help / FAQ**
page under Help/Support.

## Versioning & compatibility

- Bump `version` in `manifest.json`, mirror it in `package.json`, add a
  `CHANGELOG.md` entry; tag `vX.Y.Z`.
- `device_arch` is `any` or `os/arch`; it is rewritten per target at package time
  and checked against `supported_architectures`.
- Validation errors surface consistently across upload/API, the scanner, and the
  POS installer. The authoritative catalog is
  `ut-market-place/docs/manifest-validation-errors.md`.
