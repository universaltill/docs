# LAN multi-till sync — implementation plan (zero-touch phase D)

Status: **spec 2026-07-14** per [ADR-0011](../adr/0011-multi-till-sync.md)
(primary/replica, journals over LAN HTTP). Build in four increments, each
independently shippable and E2E-testable with two till processes on one
machine.

## Increment D1 — enrolment (QR pairing)

- Primary: Settings → **Tills** card — lists enrolled tills, "Add till"
  button shows a QR (JSON: primary URL + one-time token, 10-min expiry)
  rendered with the existing SVG barcode/QR machinery (QR needs a small
  qr encoder — pure-Go lib or vendored).
- Replica: first-boot wizard fork "**join an existing shop**" — scan/type
  the code → `POST /api/sync/enroll` on the primary → device id + sync
  bearer stored in the replica's settings; migration for a `tills` table
  on the primary (id, name, enrolled_at, last_seen_at).
- Every sync API call authenticates with the per-till bearer.

## Increment D2 — snapshot + catalog/settings pull

- Enrolment ends with a **snapshot download**: the primary's backup
  mechanism (`VACUUM INTO`, P0.2) streams the DB; the replica applies it
  via the staged-restore path (both already exist!). The replica then
  rewrites its identity keys (device id, receipt prefix `T<n>-`).
- After that (**D2b, shipped**): a pull loop (30s) fetches the primary's
  whole **admin bundle** — catalog, users, shop settings, translation
  overrides — from `GET /api/sync/admin` and applies it in one
  transaction; primary wins. *Design note:* the spec's original
  "changed since cursor" rows were replaced by a whole-bundle SHA-256
  **fingerprint** (`?have=` short-circuits an unchanged poll): most admin
  tables have no `updated_at`, and a fingerprint makes **deletes**
  propagate for free. Apply = prune-then-upsert; a pruned row still
  referenced by local sales history falls back to `is_active = 0`.
  Per-till settings never travel (`sync.*`, `printer.*`, `display.*`,
  `reports.eod_*` — `data.PerTillSettingPrefixes`). After an apply the
  replica re-derives theme/tax engine/currency/i18n in place.
- **Shared plugin settings (2026-07-17):** `plugin_settings` rides in the
  admin bundle, **global scope only** — change a shop-wide plugin setting
  (e.g. a payment gateway's secret key) on the primary and every joined
  till gets it within one pull. Register/user-scoped rows stay per-till,
  as do settings of plugins only the replica has. Apply is a per-plugin
  delete-then-insert (`data.applyPluginSettings`), not the generic
  prune/upsert: the UNIQUE index includes a NULL `scope_id` on global rows
  (SQLite treats NULLs as distinct, upserts can't target it), and the
  generic prune would wipe the replica's per-till rows. Rows for plugins
  the replica hasn't installed are skipped (FK onto `plugins`); installing
  a plugin clears `sync.pull_version` so the next tick re-delivers its
  shared settings.

## Increment D3 — sale journal push

- Replica sales queue locally (the `offline`/`sync_status` columns and
  queue already exist) and push to `POST /api/sync/sales` with lines +
  payments; the primary re-applies stock movements and the refund
  double-spend guard, records provenance (till id), and returns acks.
- Shop-wide reports/Z-report on the primary include replica sales.

## Increment D3b — stock levels follow the primary (2026-07-17)

- Every till's journal lands on the primary, making its aggregate on-hand
  the shop truth — but replicas' local levels only reflected their own
  sales. Replicas now poll `GET /api/sync/stock` (same bearer +
  fingerprint protocol as the admin bundle) in the 30s tick, **after** the
  admin apply and **only when their own journal is fully pushed**, and
  reconcile via corrective `adjust` movements through the normal movement
  path (ledger + audit intact, idempotent, primary-absent keys → zero).
- Consequence: **stock is primary-owned**. Goods-in/adjustments entered on
  a replica are overwritten by the next reconcile; the replica inventory
  page carries the same "follows the primary" banner as the catalog.
  Possible follow-up: forward replica adjustments to the primary.

## Increment D4 — UX hardening (shipped)

- Status chips on both sides per ADR-0003's "surface state, never block":
  the nav polls `/ui/sync-chip` every 30s. Replica chip = till name +
  push-queue depth, amber ⚠ when the primary hasn't answered for 90s
  (sales keep queueing). Primary chip = enrolled till count, amber when
  any till hasn't been seen for 2 minutes; links to the Tills page.
- *Deviation from this spec:* catalog edits on a replica are **not
  redirected or queued** — the catalog page shows a banner ("this till
  follows the primary; changes here are overwritten") linking to the
  primary's catalog. Redirects would need a reachability probe in the
  page path, and queued edits would need a conflict story; the 30-second
  primary-wins pull already resolves any local edit honestly. Revisit only
  if real shops lose edits this way.

## Promoting a replica (primary till died)

Every till holds the full DB, so any replica can become the shop's
primary. **Shipped (D4 follow-up):** Settings → Tills on the replica has
a "Promote this till" card (manager, type `PROMOTE` to confirm, audited
`till_promoted`). It clears the sync identity — the push/pull loops stop
on their next tick, no restart needed — but **keeps the `T<n>-` receipt
prefix** so numbering never collides with the old primary's.

After promoting:

1. On the promoted till: pair the remaining replicas again (fresh QR
   each). Joining wipes a replica's DB with the new primary's snapshot —
   do this **after** its unsynced sales pushed, or accept losing what
   never synced.
2. Per-till settings (printer, display) were never synced, so they are
   already local everywhere.
3. If the old primary comes back, treat it as a NEW till: factory-reset
   it (delete its DB) and join it to the promoted primary via the wizard.

## Pricing posture (per the monetization doc)

LAN sync is **free forever**; the identical journal protocol pointed at a
cloud endpoint becomes the paid multi-store tier.
