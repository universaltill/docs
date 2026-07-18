# Multi-cloud & sovereign distributed deployment (vision)

Status: **vision recorded 2026-07-15** (Farshid). Not scheduled — a
north star that constrains near-term choices so we don't paint ourselves
into a single-cloud corner.

## The requirement

Universal Till's cloud tier must run **distributed across multiple clouds
AND on-premise data centers**, working together as one system, because:

- **Sovereignty / sanctioned or cloud-less regions.** Some countries
  (Iran named explicitly) have no access to the global public clouds, or
  legally require data to stay in-country. A shop there must still get
  the cloud-tier features (sync, backup, marketplace, consumer app,
  identity) from infrastructure inside its own borders.
- **No lock-in (project ethos).** Same reason we self-host AI and
  identity: the platform must never depend on one vendor. Azure today,
  but the design must let a region run on Hetzner, OVH, a local IaaS, or
  bare metal in a data center.
- **Cheap and low-transaction.** The economics must work at small scale
  (a handful of shops in one country). That rules out chatty
  cross-region coordination and per-transaction cloud costs. The design
  should favor **regional autonomy with occasional, coarse-grained
  reconciliation** over constant global consensus.

## Design principles (to hold to as we build the cloud tier)

1. **Region = the unit of deployment.** Each region (a cloud or a data
   center) runs a full, self-sufficient stack: marketplace mirror,
   identity, sync endpoints, storage. A shop talks only to its region.
   A region keeps working if every other region is unreachable —
   offline-first (ADR-0003) scaled up from till to region.
2. **Federation, not a single global database.** Regions are peers that
   **reconcile asynchronously**, the same additive/primary-wins shapes
   the LAN sync already uses (ADR-0011): sale journals are additive;
   catalog/settings are owner-authoritative; identity is issuer-scoped.
   No global transactions, no cross-region locks — the property that
   makes it cheap and partition-tolerant.
3. **Content-addressed, signed artifacts travel; state stays home.** The
   marketplace already signs plugin bundles (ADR-0006); a plugin
   published in one region propagates to others as a signed artifact,
   verified locally — no trust in the transport. Same model for any
   shared catalog/reference data.
4. **Identity is issuer-federated.** Each region runs its own IdP
   instance (self-hosted, per ADR-0012); tokens are validated by JWKS,
   so a merchant/consumer is scoped to their region's issuer. Cross-
   region identity (if ever needed) is OIDC federation between issuers,
   not one central account store.
5. **Portable infra.** Kubernetes + declarative manifests (already how
   the homelab runs) so a region stands up on any k8s — managed cloud,
   self-managed, or on-prem — from the same GitOps repo. Avoid
   cloud-proprietary services on the critical path; where we use one
   (e.g. Azure DNS, SWA), keep it swappable.

## Near-term implications (so today's work stays compatible)

- Keep the sync protocol (ADR-0011) transport-agnostic and additive —
  it is already the seed of region-to-region reconciliation.
- Keep identity self-hosted and issuer-scoped (ADR-0012) — already
  compatible.
- Keep the marketplace's trust chain in the bundle, not the transport
  (ADR-0006) — already compatible.
- When the cloud tier is built, structure it as **one region we can
  clone**, never as a single global singleton.

## Open questions (decide when scheduled)

- Region discovery / routing for the consumer app (a shopper who crosses
  regions).
- Reconciliation cadence and conflict policy for any genuinely global
  data (probably: there is none — everything is regional or additive).
- Billing/commission (G26) across regions with local payment rails
  (some regions can't use Stripe — mirrors the sovereign-cloud problem).
