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
- After that: a pull loop (30s) fetches admin deltas — catalog, settings,
  users, translations — as "changed since cursor" rows; primary wins.

## Increment D3 — sale journal push

- Replica sales queue locally (the `offline`/`sync_status` columns and
  queue already exist) and push to `POST /api/sync/sales` with lines +
  payments; the primary re-applies stock movements and the refund
  double-spend guard, records provenance (till id), and returns acks.
- Shop-wide reports/Z-report on the primary include replica sales.

## Increment D4 — UX hardening

- Status chips on both sides (last sync, queue depth) per ADR-0003's
  "surface state, never block". Catalog edits on a replica redirect to
  the primary when reachable, queue-and-warn otherwise. Documented manual
  promote-replica procedure.

## Pricing posture (per the monetization doc)

LAN sync is **free forever**; the identical journal protocol pointed at a
cloud endpoint becomes the paid multi-store tier.
