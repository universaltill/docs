# Project Context (Universal Till)

This file captures the critical rules and patterns that AI agents must follow when implementing code in this project. It is optimized for context efficiency and focuses on unobvious requirements.

---

## Technology Stack & Versions

- Go: POS `go 1.25`, marketplace `go 1.25.3`, plugin `go 1.21`
- HTMX: `v2.0.7`
- SQLite: `3.51.1` (POS local DB)
- PostgreSQL: `18.1` (target `18.x` for new deployments)
- Playwright: `^1.46.0` (POS E2E), `^1.50.0` (marketplace + plugin)
- TypeScript: `^5.5.4` (POS E2E), `^5.7.2` (marketplace + plugin)

## Critical Implementation Rules

### Language-Specific Rules

- Go is the primary language; follow `go.mod` versions per repo.
- Prefer explicit, boring solutions; avoid clever abstractions.
- Money is always integer minor units.
- Domain logic must be testable without DB/network/UI; side effects live in adapters.

### Framework-Specific Rules

- Server-rendered HTML with HTMX; minimal JS.
- Kiosk/admin separation required; status/lock/exit always reachable.
- UI changes must include automated tests (backend-led UI).
- No hardcoded user-facing strings; always use locale files (`web/locales`).

### Testing Rules

- Each feature needs happy-path and edge-case tests.
- POS E2E uses Playwright under `universal-till/tests/e2e`.
- Marketplace and plugin E2E use Playwright under respective `tests/`.
- Core domain logic should be testable without DB/network/UI.

### Code Quality & Style Rules

- Repository-owned SQL only; POS SQL lives in `internal/data/*_repo.go` (no inline SQL elsewhere).
- Migrations under `internal/db/migrations/` (append-only).
- JSON fields use snake_case; API responses follow `{data, error}` shape.
- Plugins never access internal DB structures directly; use host APIs.
- Use versioned, explicit plugin contracts and permissions.
- Validate external input (user, plugins, devices, integrations).
- Critical transitions are auditable.

### Development Workflow Rules

- SQL changes require a new migration and updates to `docs/data-model.md` + ER diagrams.
- Feature work starts with a spec; changes to core domains require rationale + migration plan + tests.
- No destructive schema changes without documented migration preserving historical data.
- Core domains (Catalog, Inventory, Sales, Plugins) change slowly; breaking changes require deliberate migration.
- Pre-release only: it is acceptable to modify `universal-till/internal/db/migrations/001_init.sql` until the first release; after release, all schema changes must be append-only migrations.

### Critical Don't-Miss Rules

- Checkout must never be blocked by network; full sale completes offline.
- Secrets are never logged or stored in plain files.
- No inline SQL outside repo-owned data layer (`internal/data/*_repo.go`).
- Do not introduce hardcoded UI strings; always use i18n helpers.

---

## Usage Guidelines

**For AI Agents:**

- Read this file before implementing any code.
- Follow ALL rules exactly as documented.
- When in doubt, prefer the more restrictive option.
- Update this file if new patterns emerge.

**For Humans:**

- Keep this file lean and focused on agent needs.
- Update when technology stack changes.
- Review quarterly for outdated rules.
- Remove rules that become obvious over time.

Last Updated: 2025-12-30T15:02:44Z
