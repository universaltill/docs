# Code review — promote-replica button (LAN sync D4 follow-up)

Date: 2026-07-15 · Repo: universal-till · Branch: feat/promote-replica
Spec: docs/architecture/lan-sync.md "Promoting a replica" (updated).

## What shipped

- `SettingsRepo.ClearReplicaIdentity` — deletes every `sync.*` key
  EXCEPT `sync.receipt_prefix`: the promoted till keeps stamping `T<n>-`
  receipts so its numbering never collides with the dead primary's.
- `POST /api/sync/promote` (manager, type-`PROMOTE`-to-confirm, 409 when
  the till isn't a replica, audited `till_promoted`). No restart needed:
  the push/pull loops guard on `sync.primary_url` and simply stop on
  their next tick; the sync chip empties; the Tills page can immediately
  issue pairing QRs because enrolment was always mounted on every till.
- Tills page: "Promote this till" card rendered only for replicas, with
  plain-language guidance (unsynced sales stay local; re-pair the other
  tills afterwards). i18n en+fa.

## E2E (two processes)

Pair → restart replica → promote card visible; wrong confirm → 400;
killed the primary; promote → `sync.*` reduced to `receipt_prefix=T2-`
only; the promoted till issued a pairing token (acts as primary); a sale
rang as `T2-000000001` (prefix preserved). Guards + full suite green.

## Notes

- Sales pushed before promotion live on the dead primary; the promoted
  till's own history is complete for itself. Cross-till history recovery
  from a dead primary's disk stays a manual restore (documented).
- The old primary returning is handled by the documented factory-reset +
  join path; no automatic split-brain detection in v1.
