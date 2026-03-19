# Architecture — Plugin FAQ (ut-plugin-faq)

Part: `plugin-faq`  
Repo: `~/repos/unitill/ut-plugin-faq`

## Executive Summary

The FAQ plugin is a multilingual, offline-capable UI page plugin intended to be installed via the marketplace and surfaced inside the POS under Help/Support. It includes localized content with RTL support and a local cache model, but its entrypoint is currently a placeholder until it is wired to the POS plugin SDK.

## Technology Stack

- Language/runtime: Go (go.mod: `go 1.21`)
- Structure: plugin code under `src/` (UI rendering + storage + manifest)
- Assets: icons/content under `assets/`
- Tests: `tests/unit` and `tests/integration`

## Architecture Pattern

- **Plugin artifact**: built independently (`go build -o bin/ut-faq ./src`) and packaged for installation.
- **Navigation registration**: registers a navigation entry with route `/plugin/faq` (placeholder for POS SDK integration).
- **Offline content**: loads FAQ bundles from local cache (`data/cache`) and supports i18n/RTL in bundles.

## Key Modules

- `src/main.go`: placeholder entry; registers nav and loads a locale bundle (example: `en-US`)
- `src/ui`: UI rendering layer (FAQ page renderer)
- `src/storage`: caching layer for offline bundles
- `src/manifest`: plugin manifest assets to be validated/ingested by marketplace and POS

## Open Questions / Risks

- Define the POS plugin SDK contract and how UI routes are mounted (`/plugin/*`).
- Confirm manifest schema alignment with marketplace and POS host expectations.

