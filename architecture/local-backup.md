# Local backup & restore (P0.2)

Status: **SHIPPED 2026-07-14** (review code-reviews/2026-07-14-local-backup.md). A shop that loses its SQLite
file loses its books — no production go-live without a backup story.
Cloud backup stays the paid-tier feature (monetization gate 2); this is
the free, local, always-on safety net under it.

## Scope (v1)

- **Snapshot mechanism**: `VACUUM INTO` — SQLite's online backup; safe
  while the till is running, produces a compact single file.
  `data/backups/unitill-pos-<UTC timestamp>.db`.
- **Automatic**: daily snapshot from the existing background-jobs loop
  (first run shortly after boot if the newest backup is >24h old).
  Retention: keep the newest 14, prune older (settings `backup.keep`).
- **Manual**: Settings card (manager): "Back up now", list of existing
  backups with size/date, per-backup **Download** (copy off-device onto a
  USB stick / phone — the point of a backup is surviving the machine) and
  **Restore**.
- **Restore = stage + restart** (never swap the live DB under the app):
  restore copies the chosen backup to `data/restore-pending.db`; on next
  start, before opening the DB, the till moves the current DB aside as
  `pre-restore-<ts>.db` and puts the staged file in place. Both steps
  audited. The UI says exactly that: "restart the till to finish".
- All endpoints manager/admin-only; restore additionally requires a
  confirm phrase in the form (destructive).

## Not in v1 (noted)

Item images/`assets` (cosmetic, restorable from lookup/uploads), cloud
copies (paid tier), scheduled off-device targets (USB auto-copy — phase C
territory), encryption at rest.

## Verification

Unit: snapshot file is a valid SQLite DB with the data, retention prunes,
staged restore applied by `db.Open` path. E2E: back up via button, add a
row, restore the backup, restart, row gone + pre-restore copy exists.
