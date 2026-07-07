# Plugin Manifest

The `manifest.json` at the root of a plugin release artifact is the runtime
contract between a plugin, the marketplace, and the POS host. This documents the
**implemented** schema (verified in Epic 6); it supersedes earlier
`capabilities`/`entrypoints` sketches.

Authoritative sources:
- POS host verifier: `universal-till/internal/plugins/manifest_verifier.go` +
  `manifest.go` (the struct the Ed25519 signature is computed over).
- Marketplace validation: `ut-market-place/pkg/manifest`.
- Example: `ut-plugin-faq/src/manifest/manifest.json`.

See also: [Release Artifact](./release-artifact.md) · [Lifecycle](./lifecycle.md)

## Required fields

| Field | Meaning |
|---|---|
| `id` | Globally unique, lowercase reverse-DNS (e.g. `com.universaltill.ut-faq`) |
| `name` | Human-readable name |
| `version` | Semantic version (`MAJOR.MINOR.PATCH`, optional pre-release/build) |
| `canonical_type` | One of `page`, `button`, `payment`, `report`, `integration`, `background_job`, `device` (the POS taxonomy) |
| `executable` | Relative path to the plugin binary (e.g. `bin/ut-faq`) |
| `entrypoint` | Executable path/module (e.g. `./bin/ut-faq`) |
| `device_arch` | `any`, or `os/arch` (e.g. `linux/amd64`); rewritten per target at package time |
| `min_pos_version` | Minimum supported POS host version |
| `permissions` | Requested scopes (≥1 required by marketplace validation) |
| `locales` | Supported locales (≥1) |

## Navigation / surfaces — `entries`

Plugins expose UI/behaviour through an `entries` array. Each entry:

| Field | Meaning |
|---|---|
| `type` | `page` \| `button` \| `payment` \| `device` \| … |
| `key` | Unique within the plugin |
| `label` | Display name |
| `route` | For pages (e.g. `/plugin/faq`) |
| `icon_path`, `sort_order`, `menu_group` | Placement metadata |
| `parent_page_key`, `target_action`, `trigger_event` | For buttons/popups/hooks |

## Signature + integrity

- `signature` — Ed25519 signature (hex) over the **canonical** manifest (the
  manifest struct marshaled with `signature` emptied). The marketplace injects
  this at approval; the POS verifies it against `cfg.Marketplace.PublicKey`.
- `artifact_hash` (optional) — SHA-256 of the artifact; when present the POS
  checks it against the download-token checksum.

> The signature covers the POS `plugins.Manifest` struct's canonical JSON. The
> marketplace's `signing.CanonicalManifest` **must mirror that struct
> field-for-field** — a cross-repo test
> (`universal-till/internal/plugins/marketplace_signature_crossrepo_test.go`)
> guards against drift.

## Optional fields

`description`, `author`, `website`, `runtime` (`go`|`wasm`|`node`|…),
`settings` (config keys), `hooks` (event subscriptions), `supported_architectures`.

## Packaging relationship

- `manifest.json` must be at the **root** of the release artifact.
- Paths referenced by `entries`/resources must resolve inside the archive.
- Uploaded release `plugin_id`/`version` must match the manifest `id`/`version`
  (enforced at upload).

## Validation + compatibility

- Marketplace validation rules and messages: `ut-market-place/pkg/manifest`
  (`Validate`/`ValidateForRelease`); full catalog in
  `ut-market-place/docs/manifest-validation-errors.md`.
- POS-side required fields + `canonical_type` taxonomy + executable bit:
  `manifest_verifier.go`.
- Errors surface consistently across upload API (`{error:{message,details}}`),
  scanner (`scan_results.problems`), and POS install.

## Example (FAQ plugin, abridged)

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
