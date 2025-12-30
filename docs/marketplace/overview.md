# Marketplace Overview

Sources: ut-market-place/README.md

Purpose: Cloud-agnostic plugin marketplace; supports discovery, trust tiers, multi-version, telemetry, offline snapshots, multilingual, compliance.

Entry points:
- Production server: `cmd/marketplace/main.go` (gRPC + REST gateway + UI templates)
- Sync CLI: `cmd/marketplace-sync/main.go` (export/import bundles) — may be reused/extended for plugin onboarding.

Key routes (from README):
- `/ui/` (merchant/vendor/compliance UIs)
- `/api/` REST gateway
- `/docs`, `/redoc`, `/openapi.yaml` for API docs
- `/healthz`
- `/.well-known/marketplace-endpoints.json`

Local TLS dev: self-signed certs with prompt; see `docs/tls-local-development.md`.

Key features:
- Trust tiers (verified, approved, preview, untrusted, revoked) with review workflows.
- Multilingual (100+ locales, RTL support).
- Regional compliance/data residency support.
- Telemetry/health for plugin installs and performance.
- Offline snapshots for disconnected operation.
