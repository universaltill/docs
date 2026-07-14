# Review — end-of-day Z-report (G30 increment 1)

Date: 2026-07-14 · Repo: universal-till · Spec:
`architecture/end-of-day-report.md` (written first). Farshid: "report
generator on the background… like end of the day".

## What shipped

- Migration 013 `report_archive` (kind+period UNIQUE → the job is
  naturally idempotent) + `POSRepo.EndOfDay` (sales/refunds/net/tax-net/
  per-method in−out/receipt range), `ArchiveReport`, list/has helpers.
- **Manual**: "Run end-of-day report" on the Reports page (manager card),
  generates + archives + prints the 80mm Z-report; re-running answers
  "already exists". Archive list with per-day net and a reprint button.
- **Scheduled**: `reports.eod_enabled` + `reports.eod_time` (HH:MM,
  validated) set from the same card; a 30s loop in `pages.Init` runs the
  pure decision `eodDue(now, enabled, hhmm, alreadyDone)` — the rule is
  "past the configured time AND today's report missing", so a till that
  was **off at closing time catches up at next boot** rather than
  skipping the day. Generation audited (`report`/`eod_generated`).
- Printing is best-effort (no printer → archived only). 7 i18n keys en+fa.

## Verification

- Unit: `eodDue` table test (before/at/after time, catch-up, already
  done, disabled, malformed time); Z-report doc rendering (headers, net,
  per-method in−out arithmetic, receipt range). Full suite + guards green.
- Live E2E: run-now → "Net £14.25" — **matches the DB ground truth to the
  penny** (1425 minor units, 10 sales − 1 refund); printed bytes carry
  END OF DAY/NET/Refunds(1); second run idempotent; scheduler with a past
  time regenerated the cleared report within one 30s tick (log line
  confirms); cashier sees no card and gets 403; admin sees the archive
  row with reprint.

## Later G30 increments (spec'd)

Weekly/monthly summaries, email/push via cloud services, per-operator
breakdowns and shift variance on the Z-report, `report`/`scheduler`
plugin types as the custom-report extension point, server-side
generation for multi-store (G19).
