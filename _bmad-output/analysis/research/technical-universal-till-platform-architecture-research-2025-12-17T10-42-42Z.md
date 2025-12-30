---
stepsCompleted: [1]
inputDocuments: []
workflowType: 'research'
lastStep: 1
research_type: 'technical'
research_topic: 'Universal Till architecture: offline-first + plugin marketplace governance + cross-platform (Raspberry Pi, Android/iOS)'
research_goals: 'Identify validated technical approaches and security patterns for plugin distribution, offline-first operation, and multi-platform delivery.'
user_name: 'Farshid'
date: '2025-12-17T10-42-42Z'
web_research_enabled: true
source_verification: true
---

# Technical Research: Offline-First Architecture + Plugin Marketplace Governance + Cross-Platform

## Narrative Intro

Universal Till is aiming for a rare combination: offline-first POS, multi-repo plugin ecosystem, and a marketplace that can safely distribute extensions to potentially disconnected devices. This research focuses on proven building blocks: embedded storage, update security, artifact integrity, and practical cross-platform delivery strategies.

## Table of Contents

1. Offline-first building blocks (storage, caching, sync)
2. Secure plugin distribution (updates, signing, SBOM)
3. Marketplace telemetry/health expectations
4. Cross-platform delivery options (Raspberry Pi, Android/iOS)
5. Recommended technical direction (for BMAD stories)

## 1) Offline-First Building Blocks

### Embedded storage for edge devices

- SQLite positions itself as “Small. Fast. Reliable.” and is commonly used as an embedded database (Source: https://www.sqlite.org/index.html).
- Practical implication: POS devices can store local state reliably, then sync when connectivity exists (sync design needs its own spec).

### Offline cache and delayed delivery

- Offline-first marketplace flows often require bundling and caching (ties into CLI export/import and bundle verification).

## 2) Secure Plugin Distribution (Updates, Signing, Integrity)

### Secure update frameworks

- TUF (“The Update Framework”) describes itself as “a framework for securing software update systems” and aims to protect update systems even when repos/keys are compromised (Source: https://theupdateframework.io/).
- Recommendation: treat plugins as “updates” and model distribution using TUF-like metadata/roles to mitigate compromised marketplace or signing keys.

### Supply-chain integrity checklists

- SLSA describes itself as a framework/checklist to “prevent tampering, improve integrity, and secure packages and infrastructure” (Source: https://slsa.dev/).
- Recommendation: apply SLSA-inspired controls to plugin build/publish pipeline (e.g., provenance, hardened builds).

### Signing and verification tooling

- Sigstore docs include Cosign, and emphasize verification and threat/security models (Source: https://docs.sigstore.dev/cosign/).
- Recommendation: sign plugin bundles; verify signatures on install; keep verification keys/identities anchored to trust tiers.

### SBOM standards for plugins

- SPDX is a Linux Foundation project used for software package metadata (Source: https://spdx.dev/).
- CycloneDX positions itself as a “Bill of Materials Standard” with specifications/guides/tooling (Source: https://cyclonedx.org/).
- Recommendation: require SBOM for published plugin releases (especially for “approved/verified” trust tiers).

## 3) Marketplace Telemetry / Health Expectations

For a plugin marketplace to function as “operational truth,” it needs device-reported install state and health signals. Universal Till already documents a status model; this research links it to secure distribution patterns:

- Install intent registered by CLI.
- POS plugin host reports: requested → downloading → installing → active → failed → disabled/uninstalled.
- Health/heartbeat metadata supports compliance and support workflows.

(Lifecycle flow proposal: `docs/plugins/lifecycle.md` and CLI proposal: `docs/marketplace/cli.md`.)

## 4) Cross-Platform Delivery Options (Raspberry Pi, Android/iOS)

### Raspberry Pi / low-cost hardware

- Raspberry Pi is a hardware platform site; Universal Till’s “run anywhere” claim should map to Linux/ARM builds and device IO support (Source: https://www.raspberrypi.com/).

### Android/iOS options

Two pragmatic paths:

1) **PWA / web-app shell**  
   - MDN documents Progressive Web Apps (PWAs), including installability and web app installation experiences (Source: https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps).
   - Implication: quickest route to “mobile app” for ordering/merchant views without deep native code.

2) **Go mobile tooling for native wrappers**  
   - `gomobile` builds/runs mobile apps written in Go; docs show install and init steps (Source: https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile).
   - Implication: possible for Go-based shared logic, but UX still needs native/web UI plan.

## 5) Recommended Technical Direction (Actionable)

High-confidence building blocks (directly sourceable):
- Secure updates: model plugin delivery with TUF concepts (Source: https://theupdateframework.io/).
- Integrity framework: adopt SLSA-like controls for releases (Source: https://slsa.dev/).
- Signing: use Cosign-style signing/verification patterns (Source: https://docs.sigstore.dev/cosign/).
- SBOM: SPDX/CycloneDX for plugin packages (Sources: https://spdx.dev/ , https://cyclonedx.org/).
- Offline storage baseline: SQLite on edge devices (Source: https://www.sqlite.org/index.html).
- Mobile: PWA baseline and/or Go mobile tooling options (Sources: https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps , https://pkg.go.dev/golang.org/x/mobile/cmd/gomobile).

Story seeds this enables:
- “Plugin bundle signing + verification on install”
- “Marketplace install intent + POS status reporting contract”
- “Offline export/import bundle workflow with verification”
