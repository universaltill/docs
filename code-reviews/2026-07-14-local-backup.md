# Review — local backup & restore (P0.2)

Date: 2026-07-14 · Repo: universal-till · Spec: `architecture/local-backup.md`
(written first). Second task off the production roadmap.

## What shipped

- `internal/db/backup.go`: `Snapshot` (SQLite `VACUUM INTO` — safe online
  copy) into `data/backups/unitill-pos-<ts>.db`; `ListBackups` /
  `PruneBackups` (keep newest N, clamps to ≥1 so pruning can never delete
  every backup); `StageRestore` → `data/restore-pending.db`;
  `ApplyPendingRestore` runs in `main.go` **before** `db.Open` — the live
  DB is never swapped under a connection; the replaced file is kept as
  `pre-restore-<ts>.db` and stale `-wal`/`-shm` sidecars are removed.
- **Daily automatic backup**: goroutine in `server.Start` (deliberately
  NOT in `BackgroundJobs` — that whole scheduler only runs when a
  marketplace is configured; backups must not depend on that). Hourly
  check, snapshots when the newest is >24h old, first check 2 minutes
  after boot (tills powered off nightly still get one), keeps 14.
- Settings card (manager): Back up now, snapshot list (size/date),
  per-file **Download** (off-device copy — the help text tells the shop
  why) and **Restore** requiring the literal word `RESTORE` typed into
  the form. All endpoints manager/admin (cashier 403); backup name input
  is path-traversal-guarded (`ValidBackupName`). Everything audited
  (`backup_created/downloaded`, `restore_staged`, failures). 17 i18n
  keys en+fa.

## Verification

- Unit: snapshot opens as a valid SQLite DB containing the data;
  retention + keep=0 clamp; stage→apply round-trip restores pre-snapshot
  state, keeps the pre-restore copy, second apply is a no-op; traversal
  and missing-file names rejected. Full `go test ./...` + both guards
  green.
- Live E2E: Back up now (file created) → marker item created after the
  backup → restore without the confirm word 400 → staged with confirm →
  cashier 403 → restart → log line "staged backup restore applied", the
  marker item is gone (DB rolled back to the snapshot) and the replaced
  DB sits in backups as `pre-restore-…db`.
