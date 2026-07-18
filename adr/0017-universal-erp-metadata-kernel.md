# ADR-0017: Metadata-driven ERP kernel, plugin-based modules

- **Status:** Proposed (drafted 2026-07-18 from Farshid's design discussion;
  awaiting his explicit acceptance before implementation begins)
- **Naming (confirmed, Farshid, 2026-07-18): "Universal Core."** Sibling
  product to Universal Till (which keeps its name unchanged) — Universal
  Till is the retail/POS edge, Universal Core is the enterprise backbone
  it and other systems connect into via ADR-0014's connector plugins.
  "Universal ERP" was ruled out: it's an existing QuiqRP product, and HERA
  ERP already markets itself as an "AI-native Universal ERP" with
  near-identical positioning (unifies finance/ops/CRM/HR/inventory on one
  model, GCC-relevant marketing). "Universal Core" came back clear of
  existing ERP/enterprise-software products in a web check; **it has not
  had a formal trademark/domain clearance yet — required before any
  public launch** (a web search is not legal clearance). This ADR is
  titled around the architectural decision, not the brand, so it doesn't
  need renaming if that clearance forces a change later.
- **Relates to:** ADR-0001 (plugin runtime — WASM), ADR-0002 (20-type plugin
  taxonomy — reused for ERP modules and connectors), ADR-0003
  (offline-first — Till↔ERP sync must not block checkout), ADR-0006 (plugin
  trust chain — reused for connector plugins), ADR-0007 (document-first —
  this ADR follows it), ADR-0009 (plugin repo naming), ADR-0012 (Universal
  Till ID / Zitadel — reused as the ERP's identity provider), ADR-0013
  (plugin access tiers/monetization — reused for module entitlements),
  **ADR-0014 (ERP integration connectors — extended, not replaced: this
  platform is just another connector target for the same
  `sale.completed`-based mechanism)**, ADR-0015 (lazy registration).
- **Full supporting detail:** an internal, not-publicly-tracked backlog and
  reference data model (requirements, commercial model, feature catalog,
  and a sourced base entity model validated against a prospective
  customer's real business processes). This ADR is the public decision
  record; those internal working papers are not reproduced here, since
  they draw on a prospect's own internal documents that must not be
  quoted or detailed in a public repository.

## Context

Universal Till has proven the plugin/marketplace/identity/i18n/k8s-deploy
model at POS scale. Separately, a prospective enterprise customer
engagement (large multi-country retail group) surfaced a broader need:
enterprise operations software (ERP, CRM, accounting) that is as dynamic
and configurable as SAP or Dynamics, but where customisation is
**AI-authored metadata**, not consultant-written code (ABAP/X++/AL) — and
that is fully open source with cloud hosting sold as a subscription.

Two bodies of evidence shaped the decisions below:

- **Direct discovery with that prospective customer** confirmed several
  real, concrete requirements that a purely generic ERP design would have
  missed — details are kept in an internal, non-public working document
  (not this repo) precisely because they draw on that customer's own
  internal business-process material, which must not be quoted or
  reproduced publicly. In outline only: a specific legacy-ERP baseline to
  integrate with, a multi-country approval/governance structure, an
  international trade-finance capability, and a stated need for
  third-party ERP integration — each of which shows up as a specific
  decision below.
- **External research** (Gartner/Panorama ERP statistics, documented ERP
  failure post-mortems, 2026 agentic-AI/SOX/EU-AI-Act findings, multi-tenant
  SaaS practitioner writing, and Odoo/ERPNext's real data-portability
  track record) confirmed both the market direction (composable, API-first
  architecture is now a named industry mandate) and specific failure modes
  to design against — publicly available sources, safe to cite directly,
  full citations in the internal backlog's research section.

## Decision

### 1. Metadata-driven kernel; deterministic cores are the one exception
Business entities, forms, workflows, and validation rules are **data**
interpreted by a runtime kernel, not per-customer code. AI's role is to
**author metadata** (entity definitions, form layouts, workflow rules,
import mappings) which a human reviews and approves before it is versioned
and published — AI never generates per-customer code and never writes to
production data directly.

**Exception, hand-built and never AI-authored:** double-entry ledger
posting, tax calculation, inventory valuation, and payroll/statutory
calculations (e.g. WPS). These are small, deterministic, heavily tested
engines that the metadata layer calls into, not configures.

### 2. Modular monolith on Kubernetes; not microservices-per-module
One Go binary, module boundaries enforced as plugin interfaces (reusing
ADR-0001's WASM plugin runtime and ADR-0002's type taxonomy), deployed on
Kubernetes from day one. Splitting a module into its own service is an
evidence-based *option* later (a module with genuinely different scaling
needs — heavy analytics, the prediction engine below), never the default.
Cross-module references and master-detail relationships (§6) stay single
database-transaction and foreign-key joins, not distributed calls.

### 3. Tenancy: database-per-tenant, one shared application image
Every tenant gets its own database (required anyway — the kernel is
metadata-driven, so tenants' schemas legitimately differ); a global control
plane (tenant registry, billing, identity, marketplace) sits above regional
data planes; a tenant is homed in one region for data residency, with
backup/DR to a second. Placement tiers by cost: small tenants share a
regional Postgres server (one database each); large tenants get a dedicated
instance or cluster — same application image throughout, including
self-hosted installs (a self-hosted deployment is just a single-tenant
instance of the same system).

**Named risk, not deferred:** database-per-tenant is documented by
practitioners as not scaling past roughly a few hundred tenants without an
automated migration pipeline. The canary-first, resumable, per-tenant
schema/metadata migration system must exist **before** tenant count grows
into the hundreds, not as later hardening.

### 4. Storage: Postgres-first, polyglot only by evidence
PostgreSQL is the system of record, including JSONB for tenant-dynamic
entities/fields (§7) — no separate document database. Caching is a ladder
(none → in-process Go cache for hot/rarely-changed data like compiled form
definitions and permissions → shared Valkey/Redis only at multi-replica
scale); ledger truth is never served from cache. Object storage (S3-
compatible, self-hostable via MinIO) for documents from day one. Kafka,
dedicated OLAP stores, and search engines are added only when a workload
proves Postgres insufficient — not built in speculatively.

### 5. One Entity Definition → the full generated CRUD stack
A single declarative Entity Definition (fields, relationships, permissions,
lifecycle hooks) is the only thing a human or an AI ever authors. Storage,
CRUD API + OpenAPI docs, list/detail/edit forms, validation, RBAC
enforcement, audit logging, search indexing, import/export mapping, and
i18n scaffolding are all *derived*, never hand-coded per entity. All three
authoring paths — a hand-built base module, an AI-drafted entity from a
plain-language request, an entity auto-discovered during import — produce
the same Entity Definition format and go through the same generator.

### 6. Form Definition schema, with master-detail as a first-class pattern
Form layout is a versioned, DB-stored (Postgres JSONB; YAML/JSON is the
human-readable export/review format, never the live runtime store)
declarative definition: sections, fields (with type, validation, and
conditional `visible_if` rules), actions, and navigation. Three distinct
relationship mechanisms, not one:
1. **Reference field** — points to an independently existing entity
   (picker widget).
2. **Master-detail (composition)** — e.g. Purchase Order → PO Lines. Detail
   rows have no existence without the master; saved atomically in one
   transaction, with roll-up/calculated fields and inline-editable grids.
   This is the dominant pattern across the reference data model and must
   be a first-class relationship type, not bolted on.
3. **Related list (reference-only)** — a read-only view of other
   independently existing records, for context/navigation, not part of
   the same save.

Action buttons stay a small declarative verb set (`save`, `workflow.start`,
`report.render`, `navigate`) calling into the workflow engine (§8); no
scripting language embedded in form metadata.

### 7. Dynamic fields/entities at import time, governed
Data from an external system (e.g. an SAP Z-table or a NAV custom field)
that doesn't fit the canonical model can create new field/entity metadata
at import time, stored in the tenant's JSONB extension — never a literal
per-tenant schema migration. A dedup check runs before creating anything
new. Dynamic/unmapped data is visible and reportable immediately but is
never silently wired into the deterministic cores (§1) — promoting a field
into financial logic is a separate, explicit, reviewed act.

### 8. Base domain models + a stable foundation layer
The kernel ships opinionated standard entities per domain (Finance,
Procurement, Inventory, Manufacturing, Sales, CRM, HR, Projects, Assets —
full model in an internal reference document, built on the Party–Role–
Relationship pattern and cross-checked against a real prospective
customer's documented processes). **Foundation entities used by every module (Party, Item/Product
master, UOM, Currency) are always present**, independent of which
operational modules a tenant licenses (§12) — a tenant using only Sales
still needs to reference an Item.

### 9. Workflow/event engine as a core kernel service
An event bus (every entity change + external triggers) and declarative,
AI-draftable/human-approved workflow definitions, executed by a durable,
transactional job queue on Postgres (retries, dead-letter, idempotent,
resumable) — not a dedicated durable-execution system on day one.
Financial side effects always go through the deterministic cores' own
controlled API, never a direct write from a workflow step.

### 10. Prediction/recommendation layer, cross-module
A single kernel prediction service (time-series forecasting, propensity/
risk scoring, anomaly detection — mostly classical statistics, not an LLM)
serves every module (stockout/overstock, cash-flow, churn, attrition,
predictive maintenance, etc.) rather than each module inventing its own.
Predictions raise events through the workflow engine as recommendations;
a human approves before anything transacts. Explainability is mandatory
for finance/HR predictions.

### 11. Integration: extend ADR-0014, don't replace it
`integration`-type plugins (ADR-0002, ADR-0006's trust chain) are the
mechanism for every external connection, in both directions:
- **This platform → other ERPs** (SAP, Dynamics, NAV, QuickBooks/Xero/
  Sage), banking/trade-finance (ISO 20022, LC/DP/TT), government/compliance
  (e-invoicing, WPS payroll), communications (email/SMS/**WhatsApp
  Business API**), e-commerce/marketplaces, identity/SSO federation
  (SAML/OIDC/LDAP — a customer's own IdP, not a forced new account),
  logistics carriers, BI export, IoT/hardware, and generic outbound
  webhooks.
- **Universal Till → this platform** reuses ADR-0014's existing
  `sale.completed` event and connector-plugin pattern unchanged: this ERP
  is simply another connector target alongside SAP and Dynamics, not a
  special integration path. No new Till-side architecture is needed.
- **Parallel-run sync with a live legacy ERP** (the coexistence strategy)
  is a kernel capability, not a one-off script: a system-of-record
  registry per entity type (`read-only → bidirectional → owned`, mirroring
  Observe→Assist→Transact→Own), idempotent change capture, and scheduled
  reconciliation against the legacy system as a first-class subsystem.

### 12. Client-selectable modules via the existing marketplace mechanism
A "module" (Finance, Inventory, Procurement, …) is an installable bundle of
Entity Definitions + workflows + base schema, gated by entitlement through
the **same marketplace/plugin mechanism already built for Universal Till's
POS plugins** — not a new system. A module dependency graph is enforced
(e.g. Procurement depends on the Item/Vendor foundation). Module selection
is a licensing/entitlement concern, orthogonal to the deployment topology
decided in §2.

### 13. Licensing and commercial model
Platform: **AGPLv3** (blocks closed-source resale of a hosted fork while
remaining genuinely open source); plugin SDK: Apache-2.0 (third-party
plugin authors aren't forced to open their plugins); trademark on the
product name; a **CLA required from day one** to keep relicensing possible
later. **No company-size restriction on free self-hosted use** — legally
incompatible with OSI open source, unenforceable in practice, and
unnecessary (enterprises pay for support/SLA, not for permission to run
the code). Three commercial tiers: self-hosted free; self-hosted + paid
support/SLA; cloud = subscription only. A feature is cloud-gated only if
it is inherently a hosted service (backups, managed upgrades), never an
artificial flag in otherwise-identical code.

### 14. AI governance, hardened beyond "draft, approve, version, rollback"
Every AI-authored change (entity, field, mapping, workflow, form) is
drafted, human-approved, versioned, and rollbackable — already the
baseline. Additionally: **the AI's identity is a first-class part of the
audit trail from day one** — which agent, which model/version, which
input produced a given change, distinguishable from human-authored changes
— rather than retrofitted later the way legacy vendors are now being
forced to under EU AI Act Article 12 and SOX's treatment of AI-influenced
financial/HR/procurement processes as internal-control risks.

### 15. Anti-sprawl governance and verified export
Two additions beyond the individual review gate, because manual review is
documented to fail once customisation volume grows (the low-code
governance research): a scheduled **customisation health check** (near-
duplicate entities, overlapping workflows, rising complexity per tenant)
surfaced to the tenant's own IT governance; and a scheduled **export
drill** that periodically proves a tenant's data *and* customisation
metadata can actually be reconstructed from its own export — a stronger,
tested claim than Odoo's documented Community-edition export failure or
ERPNext's untested promise.

### 16. Repository structure and code-quality rules

**Repository structure — mirrors and reuses Universal Till's existing
conventions, doesn't invent new ones:**
- **One kernel repo** ("Universal Core" itself): the metadata engine, the
  entity/form generator, the workflow engine, the deterministic cores
  (§1), and the base/foundation domain modules (§8 — Finance, Inventory,
  Procurement, etc.) as clean, separately-testable Go packages *within*
  this one repo. Not one repo per base module — they compile into a
  single binary and ship as one versioned release, consistent with §2's
  modular-monolith decision. Splitting them into repos would add
  cross-repo dependency and versioning overhead with no matching
  deployment benefit, since they aren't independently deployed.
- **Separate repos for everything actually pluggable** — connectors
  (§11's `integration` plugins), country/tax packs, industry-specific
  modules — reusing the existing `ut-plugin-{type}-{name}` convention
  (ADR-0009) exactly as Universal Till plugins do: own repo, own CI
  pipeline, own versioning, own signing through ADR-0006's trust chain.
- **Tenant customisations are not code and have no repo at all** — they
  are metadata rows (§§5–7), living and versioned in the tenant's own
  database. Worth stating explicitly so nobody is tempted to "commit" a
  customer's custom fields or workflow as a code change.
- The docs repo's existing rules (ADR/spec before build, review doc per
  substantive change, docs move with code in the same session — see
  `docs/CLAUDE.md`) apply to this product exactly as they do to Universal
  Till. No separate process invented.

**Clean-code rules — specific and enforceable, not a vague aspiration:**
- **Generated surfaces are never hand-patched.** A fix to a generated CRUD
  screen or API endpoint goes into the Entity/Form Definition or the
  generator itself, never a one-off patch to generated output. This is
  the rule that stops the platform from quietly recreating the exact
  SAP/consultant-coding sprawl it exists to replace.
- **Deterministic cores (§1) get the strictest bar in the codebase**:
  mandatory human code review (never AI-merged unreviewed), golden-master
  or property-based tests, no direct AI-authored change without a human
  review pass — a deliberately higher bar than the rest of the kernel.
- **Layering discipline in the same spirit as ADR-0005** (raw SQL only in
  repositories): domain/entity logic must not import HTTP/web-framework
  code; a lint-enforced boundary between the metadata engine's generic
  core and any per-domain business logic; plugin/WASM sandbox boundaries
  enforced by tests (reusing ADR-0006's trust chain), not left to
  convention alone.
- Standard Go discipline already established for Universal Till carries
  over unchanged: golangci-lint/gofmt gated in CI, table-driven tests,
  small interfaces, explicit error handling, context propagation. Not new
  rules — confirmed inherited, not reinvented per repo.

**Two different meanings of "AI writes this" — kept deliberately distinct,
since conflating them is an easy and consequential mistake:**
- AI (Claude/Fable) writing the **kernel's own source code** (the
  generator, the workflow engine, the ledger implementation) is a
  development-time activity: normal engineering discipline applies in
  full — code review, tests, CI, an ADR for architectural decisions, a
  review doc per commit.
- AI authoring **tenant metadata at runtime** (a customer's custom field,
  a workflow rule) is a *product feature*, governed entirely by §14's
  draft → approve → version → rollback rules — a completely different
  activity wearing the same model's name.
- "AI builds this product" (true, a development-time claim) must never be
  allowed to blur into "AI can freely rewrite tenant business logic in
  production" (false, and precisely the failure mode §§14–15 exist to
  prevent).

## Consequences

- **Enables:** modules ship in days once the kernel exists, not months;
  one codebase serves self-hosted, sovereign/on-prem, and managed-cloud
  customers; coexistence with a customer's existing ERP is a product
  capability, reusable across every prospect, not a bespoke integration
  project; engagements like this one validate the product rather than
  consuming one-off effort.
- **Constrains:** the deterministic cores (§1) and any capability that
  touches them (WPS-format payroll, IFRS 16 lease accounting, FEFO
  inventory valuation, multi-entity consolidation, segregation-of-duties/
  approval-matrix) require real engineering and cannot be short-cut by
  the metadata layer, however flexible it is elsewhere.
- **Risk carried forward, must be actively managed:** the same flexibility
  that makes customisation cheap could enable a customer to recreate
  Lidl's SAP failure (refusing to adapt process, accumulating unbounded
  bespoke customisation) at higher speed; §15's health check is a mitigation,
  not a guarantee — process discipline still matters.
- **Depends on:** an actual discovery workshop with the prospective
  customer's department leads to close remaining field-level gaps (WPS,
  PRO/labor-card, staff accommodation, commission, real estate/lease, F&B
  recipe costing) that document evidence alone cannot resolve.

## Rollout

1. **Kernel spike** — metadata/entity engine, §6's form renderer including
   master-detail, one §9 workflow, minimal §1 ledger core, §14's AI-actor
   audit identity built in from this first pass (not retrofitted). Demo-
   grade; can double as the prospective-customer demonstration.
2. **Foundation layer** (§8) — Party/Role/Relationship, Item/UOM/Currency —
   before any operational module, since everything depends on it.
3. **First two modules** — management reporting/workflow and one
   operational module (procurement/stock intelligence, matching the
   customer demo scenario), in shadow/read-only mode against a real or
   synthetic legacy-ERP connector (§11).
4. **Module entitlement/marketplace wiring** (§12) once at least two
   modules exist to select between.
5. **Migration-orchestration pipeline** (§3) before onboarding pushes
   tenant count past low hundreds — not deferred.
6. Customer discovery workshop to close remaining field-level gaps, in
   parallel with the above, not blocking the kernel spike.
7. **Formal trademark + domain clearance** on the final product name
   ("Universal Core" or otherwise) before any public-facing use — a web
   search is not legal clearance.
