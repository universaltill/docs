# Coding Standards & Enforced Policies

These are **rules, not suggestions.** They exist to keep the codebase consistent
across repos and contributors (human or AI). Deviations must be called out in the
PR and justified. The [code review before every commit](../for-developers.md#reviews--commits)
checks these.

---

## 1. Data access — repository pattern (enforced)

**All data-access code lives in one place per repo. No inline SQL anywhere else.**

- **POS (`universal-till`):** every SQL statement lives in the repo-owned data
  layer — `internal/data/*_repo.go`. Handlers, services, and UI code call
  repository methods; they never build or run SQL themselves.
- **Marketplace (`ut-cloud`, renamed from `ut-market-place` 2026-07-19):** persistence goes through the **ent** client
  and `internal/repositories/`. The **ent schema is the single source of truth**;
  the DB is produced by auto-migrate, not hand-written SQL.
- **Plugins never touch host internals.** A plugin accesses data only through the
  host's plugin APIs/permissions — never the POS database directly.

> **Anti-pattern:** inline SQL in a handler or service. If you're writing SQL
> outside the data layer, stop and add a repository method instead.

## 2. Schema & migrations

- **POS:** migrations under `internal/db/migrations/`, **append-only** after the
  first release (pre-release, `001_init.sql` may still be edited). No destructive
  schema changes without a documented migration that preserves historical data.
- **Marketplace:** change the ent schema (`internal/repositories/ent/schema/*`),
  then `go generate ./internal/repositories/ent`. The schema drives the DB.
- Core domains (Catalog, Inventory, Sales, Plugins) change slowly; breaking
  changes require a deliberate migration plan.

## 3. Naming

| Thing | Convention | Example |
|---|---|---|
| DB tables | plural snake_case | `plugins`, `plugin_entries` |
| DB columns | snake_case | `plugin_id`, `created_at` |
| Foreign keys | `<entity>_id` | `sale_id` |
| Indexes | `idx_<table>_<column>` | `idx_sales_created_at` |
| REST endpoints | plural, versioned | `/api/v1/plugins` |
| Route params | `{id}` in docs | `/api/v1/plugins/{id}` |
| Query params | snake_case | `since_version` |
| Custom headers | `x-` prefixed | `x-marketplace-api-version` |
| Go packages | lower_snake | `plugin_runtime` |
| Go files | lower_snake.go | `plugin_manager.go` |
| Handlers / services | `HandleX` / `XService` | `HandleInstall`, `CatalogService` |

## 4. API & data formats

- Success: `{ "data": …, "error": null }`. Error: `{ "error": { "code", "message" } }`.
- **JSON fields are snake_case.** (CamelCase JSON is an anti-pattern.)
- Dates are ISO-8601 strings. **Money is integer minor units — always.** In the
  POS this is the distinct `internal/money.Money` type, so the compiler blocks
  mixing money with quantities/rates; it marshals as the same integer. Convert
  to/from raw `int64` only at DB / external-DTO boundaries.
- Plugin/contract payloads carry explicit `version` fields.
- Validate **all** external input (user, plugins, devices, integrations).

## 5. Events & lifecycle

- Event names: `domain.action` (e.g. `plugin.installed`); payloads include
  `version`, `timestamp`, `source`.
- Install/status lifecycle is fixed:
  `requested → downloading → installing → active → failed`.
- Background sync and install state must be **non-blocking**.

## 6. Offline-first (non-negotiable)

- **Checkout must never be blocked by the network** — a full sale completes offline.
- Never fail checkout for offline/network errors; surface status via chips/banners,
  not modal blockers, in the kiosk flow.
- Kiosk/admin separation: status/lock/exit must always be reachable.

## 7. Internationalization

- **No hardcoded user-facing strings.** All copy goes through locale files
  (POS: `web/locales`). RTL locales must render correctly.

## 8. Testing & structure

- Domain logic must be testable **without DB/network/UI**; side effects live in
  adapters/repositories.
- Every feature needs happy-path **and** edge-case tests. Tests are co-located
  (`*_test.go`). E2E uses Playwright under each repo's `tests/`.
- Reusable helpers live in `internal/<area>/` — no global `utils` sprawl.
- Config via env + a committed `.env.example`.

## 9. Security & auditability

- Secrets are never logged or written to plain files (prod secrets come from Key
  Vault — see [deployment.md](deployment.md)).
- Critical transitions are auditable (POS `audit_log`, marketplace `AuditEvent`).
- Use versioned, explicit plugin contracts and permissions.

---

## Review checklist (apply on every PR)

- [ ] No SQL outside the data layer / ent repositories.
- [ ] Naming matches §3; JSON is snake_case; response shape is `{data,error}`.
- [ ] Money is integer minor units.
- [ ] Migrations are append-only (post-release) and non-destructive.
- [ ] No hardcoded UI strings — locale files used.
- [ ] Offline-first guarantees preserved; checkout never blocks on network.
- [ ] Happy-path + edge-case tests added; domain logic testable without I/O.
- [ ] External input validated; secrets not logged.

Record any deliberate deviation in the PR description and, if structural, in an
architecture addendum.
