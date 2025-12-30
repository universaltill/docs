# Plugin Developer Guide

Sources:
- ut-market-place/docs/plugin-developer-guide.md
- ut-market-place/docs/plugin-development-ai-guide.md
- ut-market-place/docs/manifest-validation-errors.md
- ut-market-place/pkg/contracts/README.md

Topics to consolidate:
- Manifest schema and validation errors.
- Release workflow, trust tiers, versioning/rollback.
- i18n expectations (100+ languages, RTL) and compliance hooks.
- API/CLI touchpoints for publishing and bundle upload.
- Security and compatibility contracts (see contracts/COMPATIBILITY.md, VERSIONING.md).
- Offline snapshot/bundle expectations for disconnected stores.

Key points from plugin-developer-guide (summary):
- Trust tiers: verified/approved/preview/untrusted/revoked, with security review and quality metrics.
- Supported plugin types: payments, loyalty, reporting/analytics, inventory, tax calculators, receipt printers, employee management, integrations.
- Lifecycle: init → register hooks/capabilities → active → shutdown; offline cache expected.
- Prereqs (example): developer account/KYC, Go 1.25+ or TinyGo-compatible; SDKs in Go/Node/Python.
- Version management: multiple releases and rollback supported.
- Submission: packaging, automated validation, then manual review for higher tiers.
