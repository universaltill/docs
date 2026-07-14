# 0011 — Multi-till sync: one primary till per shop, LAN replicas

**Status:** accepted (2026-07-14)

## Context

A shop's second till must see the same catalog, stock, held sales and
settings as the first (zero-touch phase D: "the 2nd till joins by scanning
a QR on the 1st"). Constraints that decide the shape:

- **Offline-first is binding (ADR-0003):** every till must complete sales
  with the network down — including the shop's own LAN.
- SQLite is the store (ADR-0005); there is no server anywhere in the free
  tier, and we will not add one (a shop must not need to run a "server").
- Stock is the only truly contended state (two tills selling the last
  item); catalog/settings changes are rare and administrative.
- The paid cloud tier later syncs *shops*, not tills — whatever we pick
  must become the cloud protocol's client unchanged.

## Decision

**Primary/replica per shop, over HTTP on the LAN, with sale journals as
the unit of sync.**

1. **One till is the primary** — the first till installed. It owns the
   authoritative catalog, settings, users and stock. Its existing HTTP API
   is the sync surface (no new server process).
2. **Replicas pull, then push.** A replica keeps a full local copy
   (snapshot download = the existing backup file, then periodic deltas).
   Sales made anywhere are **journaled locally and pushed** to the
   primary; the primary applies stock movements in arrival order.
   Replicas never write catalog/settings directly — those edits redirect
   to (or proxy through) the primary when it's reachable.
3. **Offline behaviour:** a replica that loses the primary keeps selling
   from its local copy and queues its journal (the sale-sync queue and
   `offline` flags already exist on sales). Stock may transiently oversell
   across tills while partitioned — accepted; the shop's
   allow-negative-inventory policy already governs this, and reconciliation
   is arithmetic (movements are additive deltas, not absolute sets).
4. **Identity & enrolment:** joining = scanning a QR shown on the primary
   (Settings → Tills). The QR carries the primary's URL + a one-time
   enrolment token; the replica receives a device id + a shared bearer for
   the sync API. Operators/PINs sync like other admin data, so any staff
   member can log into any till.
5. **Conflict rules (fixed, simple):** stock = sum of movements (no
   conflict by construction); catalog/settings = primary wins, last write
   on the primary wins; receipts = per-till prefixes (`T2-000123`) so
   numbers never collide; refund double-spend guard re-checked on the
   primary at journal apply.
6. **Free forever on the LAN.** The same journal/push protocol pointed at
   a cloud endpoint later becomes the paid multi-store sync; nothing here
   is throwaway.

## Consequences

- No new runtime dependencies; the sync client is a background loop in
  the till (like catalog sync / backups).
- Primary failure = shop still sells (replicas are full copies); promote
  a replica manually by re-scanning a QR (v1: documented procedure, not
  automatic failover).
- The wizard gains a "join existing shop" fork (phase B leftover) once
  enrolment exists.
- Cross-till reporting (Z-report for the whole shop) reads consolidated
  data on the primary.
