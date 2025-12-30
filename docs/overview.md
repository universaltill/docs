# Universal Till Documentation (Centralized)

This repository centralizes Universal Till docs across POS, marketplace, and plugins, replacing scattered Speckit-era notes. Sources merged so far:
- docs-current/README.md (root overview)
- universal-till/README.md (product positioning/features)

## What This Covers
- Platform overview and key value points
- Links to architecture, POS, marketplace, and plugin docs in this folder
- Pointers to legacy specs (see `docs/specs/` for Speckit references)

## Workspace Layout (Multi-Repo)
- Root workspace: `~/repos/unitill`
- POS (core app): `~/repos/unitill/universal-till`
- Marketplace service: `~/repos/unitill/ut-market-place`
- Sample plugin: `~/repos/unitill/ut-plugin-faq`
- Future repos: additional plugins in `~/repos/unitill/ut-plugin-*`

## Quick Facts
- Offline-first POS + back office (with optional head office/cloud core).
- Runs anywhere: Raspberry Pi, low-cost tills, Android/iOS (future app), general hardware.
- Written in Go (Golang).
- Plugin ecosystem: marketplace for discovery/install; “everything is a plugin” for POS/back office (payments, taxes, hardware, integrations).
- Free POS; cloud services are paid/optional.
- Multi-language and multi-currency.
- Local rules (tax, compliance, regional specifics) are pluggable.
- Broad integrations via plugins: ERP, ecommerce (eBay, Amazon, etc.), accounting, delivery, etc.
- Future mobile app: map view of tills; order flows (delivery/restaurant) via plugins.

## Next Steps
- Complete doc migration from repo READMEs and specs into the sections below (docs-current content has been consolidated here; the legacy folder can be archived/removed).
- Align stories/ACs/architecture to BMAD formats.
