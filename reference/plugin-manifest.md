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
| `canonical_type` | The plugin's primary type — one of the taxonomy below |
| `executable` | Relative path to the plugin binary (e.g. `bin/ut-faq`) |
| `entrypoint` | Executable path/module (e.g. `./bin/ut-faq`) |
| `device_arch` | `any`, or `os/arch` (e.g. `linux/amd64`); rewritten per target at package time |
| `min_pos_version` | Minimum supported POS host version |
| `permissions` | Requested scopes (≥1 required by marketplace validation) |
| `locales` | Supported locales (≥1) |

## Plugin type taxonomy

`canonical_type` (the plugin) and `entries[].type` (each surface it registers) share
one taxonomy, enforced by the POS at manifest parse time and by the
`plugin_entries.type` CHECK constraint:

| Type | Meaning |
|------|---------|
| `page` | Adds a page to the POS (menu entry → rendered content bundle or static HTML) |
| `button` | Adds an action button (products panel or a parent page); press publishes its event |
| `popup` | Modal/overlay triggered by an event (`trigger_event`) |
| `payment` | A tender method offered during checkout |
| `device` | Peripheral driver (barcode scanner, scale, customer display) |
| `integration` | Connects the till to an external system (accounting, ecommerce, …) |
| `report` | Adds a report to the Reports area |
| `pricing` | Price rules/promotions engine hooks |
| `tax` | Tax calculation rules for a jurisdiction |
| `import` | Data importer (catalog, customers, …) |
| `export` | Data exporter (feeds, backups, …) |
| `hardware` | Low-level hardware support (printer protocols, cash drawer) |
| `background_job` | Long-running/background work owned by the plugin runtime |
| `scheduler` | Time-based triggers (cron-like) for actions/events |
| `receipt_template` | Receipt layout/content (legal text blocks, branding) |
| `customer_facing` | Customer-side screens (second display, self-service) |
| `auth` | Authentication providers (PIN pads, badges, SSO) |
| `notification` | Outbound notifications (SMS/email/webhooks) |
| `delivery` | Delivery/order-ahead platform integration |
| `theme` | Restyles/repositions the POS UI (CSS, asset-only) |

The engine currently renders `page`, `button` and `theme` natively; other types are
registered, listed on the plugin info card, and dispatched to their engines as those
land (payment → tender integration is next).

## Navigation / surfaces — `entries`

Plugins expose UI/behaviour through an `entries` array. Each entry:

| Field | Meaning |
|---|---|
| `type` | One of the taxonomy below |
| `key` | Unique within the plugin |
| `label` | Display name, rendered through the POS translator. Plain text passes through unchanged; to localize it, use a key (e.g. `plugin.faq.menu`) and ship `locales/<locale>.json` overlay files in the bundle — the same mechanism language packs use (any active plugin may ship translations for its own strings). |
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
