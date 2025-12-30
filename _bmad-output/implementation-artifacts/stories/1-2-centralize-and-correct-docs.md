# Story 1.2: Centralize and Correct Documentation (Single Source of Truth)

Status: ready-for-dev

## Story

As a maintainer,
I want all Universal Till documentation consolidated into this `docs` repository with a clear structure and corrected statements,
so that contributors can reliably understand the current system across POS, marketplace, and plugins without chasing conflicting README/spec fragments.

## Acceptance Criteria

1. A single “docs hub” exists with a clear table of contents and links to POS, marketplace, and plugin documentation.
2. Key platform promises are captured consistently: offline-first, runs-anywhere, Go stack, everything-as-plugin, free core with optional paid cloud, multi-language/currency, pluggable local tax/compliance, integrations via plugins, future mobile app vision.
3. Each section (POS/marketplace/plugins) includes: current state, intended state, and known gaps (e.g., CLI dependency, plugin add/install not yet complete, POS UI quality gap).
4. Documentation that is demonstrably incorrect or outdated is either corrected or explicitly marked as “legacy” with pointers to the updated location.
5. Legacy Speckit-era specs remain accessible but are clearly separated and labeled as inputs (not current truth).

## Tasks / Subtasks

- [ ] Establish the central structure and navigation (AC: 1)
  - [ ] Maintain/update `docs/README.md` as the entrypoint
- [ ] Normalize platform feature statements across overview/architecture (AC: 2)
  - [ ] Keep “feature promises” in `docs/overview.md` and “system shape” in `docs/architecture.md`
- [ ] Add “current vs intended state” sections per area (AC: 3)
  - [ ] POS: `docs/pos/*`
  - [ ] Marketplace: `docs/marketplace/*`
  - [ ] Plugins: `docs/plugins/*`
- [ ] Separate legacy specs from current docs (AC: 5)
  - [ ] Maintain `docs/specs/README.md` as index and mapping plan

## Dev Notes

- Source material to migrate and reconcile:
  - POS docs/specs: `~/repos/unitill/universal-till/docs`, `~/repos/unitill/universal-till/specs`
  - Marketplace docs/specs: `~/repos/unitill/ut-market-place/docs`, `~/repos/unitill/ut-market-place/specs`
  - FAQ plugin docs/specs: `~/repos/unitill/ut-plugin-faq/README.md`, `~/repos/unitill/ut-plugin-faq/specs`
  - Legacy docs in this repo: `docs-current/`

### References

- `docs/README.md`
- `docs/overview.md`
- `docs/architecture.md`
- `docs/specs/README.md`
