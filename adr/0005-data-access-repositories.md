# 0005 — Raw SQL only in repositories

**Status:** accepted (2026-07-07, mechanically enforced)

## Decision
POS: SQL text lives only in `internal/data` (repos) + `internal/db`
(migrations) — `scripts/ci/guard-data-access.sh` fails CI otherwise.
Marketplace: depguard denies `database/sql` outside its data layer.
Handlers/domain never embed queries; add a repo method instead.
