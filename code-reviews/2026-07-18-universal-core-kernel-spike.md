# Code review — Universal Core kernel spike (first increment)

Date: 2026-07-18 · Repo: universal-core (new) · Branch: main
Spec: `adr/0017-universal-erp-metadata-kernel.md`, rollout §1.

## What shipped

New repo `universal-core` (AGPLv3, local only — **not yet pushed to
GitHub**, see "Not pushed" below), scaffolded to match `universal-till`'s
conventions (CLAUDE.md, repository-pattern rule, module layout). First
several increments of the kernel spike from ADR-0017's rollout plan:

- **`internal/kernel/entity`** — the Entity Definition model (§5): fields
  with type/required/default/enum-values, and the **three distinct
  relationship kinds** from §6 (`reference`, `composition`, `related_list`)
  as separate types rather than one conflated concept. `Definition.Validate`
  checks internal consistency (duplicate fields, enum without values,
  reference without target, composition without a parent field).
  `ValidateRecord` is the server-side half of "validation defined once,
  applied identically client/server" — driven entirely by the Definition,
  never by an entity-type name check.
- **`internal/kernel/ledger`** — the deterministic double-entry core
  (§1/§16). `Entry.Validate` enforces: at least one line, every line has
  exactly one of debit/credit set and non-negative, and total debits equal
  total credits. Covered by a property-style test that generates 200
  random balanced entries (always pass) and perturbs each by 1 minor unit
  (always rejected as unbalanced) — this is the one invariant the whole
  ledger's trustworthiness rests on, so it's tested as an invariant, not
  just example cases.
- **`internal/kernel/audit`** — AI-actor identity as a first-class citizen
  of the audit trail (§14/§16), not retrofitted: `Actor{Type, ID,
  ModelVersion, Input}`, `ActorType` is `human` or `ai_agent` (no vague
  third "system" bucket that would hide which one acted). An `ai_agent`
  actor without a `ModelVersion` is rejected at construction. Input is
  SHA-256 hashed, never stored raw, so a specific AI draft can be
  correlated later without retaining free text in the audit log.
- **`internal/kernel/crud`** — the generic engine (§5): given a
  Definition, `Create`/`Update` validate the incoming data, then write the
  record **and** its audit entry in one transaction — a record can never
  exist without its audit row, and a validation failure writes nothing.
  This package contains no entity-specific logic; behaviour comes only
  from the Definition passed in.
- **`internal/kernel/form`** — the Form Definition schema (§6): sections,
  fields with `visible_if` conditional visibility, and a small closed set
  of action ops (`save`, `workflow.start`, `report.render`, `navigate`) —
  regression-tested (`TestDefinitionValidate_RejectsArbitraryOp`) so the
  schema can't quietly grow into a scripting language. **Three distinct
  section component types**, corrected during design after an earlier
  draft wrongly conflated two of them: `fields` (a plain group),
  `master_detail` (composition — atomic save, `roll_up` field, no
  independent existence without the parent), and `related_list`
  (read-only, independently-existing records). Worked example in the
  tests: a Purchase Order form with an LC-reference field visible only
  when `payment_method == 'LC'`, and a master-detail `Lines` section
  rolling line totals into the header total.
- **`internal/kernel/workflow`** — workflow definitions (§9): a trigger
  (`on_create`/`on_update`/`manual`) and a closed set of step kinds
  (`require_approval`, `notify`), with the same declarative-only guardrail
  as the form package. `Execute` runs steps in order and **halts at the
  first `require_approval` step** rather than proceeding automatically —
  the Observe→Assist→Transact→Own gate enforced at the executor level,
  not just stated as policy. Deliberately a synchronous, in-memory
  executor for this spike; the durable, transactional Postgres job queue
  (retries, dead-letter, resumable) that §9 specifies for production is
  not built yet.
- **`internal/data`** — repositories (`RecordRepo`, `AuditRepo`), the only
  place raw SQL is allowed, per this repo's own CLAUDE.md. Every method
  takes `tenantID` explicitly; nothing relies on ambient tenant context.
- **`internal/db/migrations/001_init.sql`** — foundation schema:
  `tenants`, `entity_definitions` (versioned, draft/approved/published/
  rolled_back), `form_definitions`, `records` (generic JSONB storage per
  §4/§7), `audit_log` (with `actor_type`/`model_version`/`input_hash`
  columns from the first migration, not added later), and the ledger
  tables (`gl_accounts`, `journal_entries`, `journal_lines`).
- **`cmd/universal-core`** — minimal runnable entrypoint: connects to
  Postgres, serves `/healthz`. Not yet a real API surface.

## Testing

Unit tests for `entity`, `ledger`, `audit` need no database and run in
`go test ./...` with no setup. Integration tests for `crud` need
`TEST_DATABASE_URL` and **skip (not fail)** when it's unset, so the suite
stays green for anyone who clones the repo without Postgres configured.

Ran the integration suite against an isolated, throwaway Postgres 16
instance (own data directory, non-default port, torn down afterward — no
trace left on the machine, no existing local Postgres touched) and
verified:

- Record + audit entry commit atomically (`TestEngine_Create_WritesRecordAndAuditAtomically`).
- An AI-agent actor's model version and input hash are recorded distinctly
  from a human actor's audit row (`TestEngine_Create_RecordsAIActorIdentity`).
- A validation failure writes **nothing** — no orphaned record, no audit
  row (`TestEngine_Create_ValidationFailure_WritesNothing`).
- An update appends a second audit row rather than losing the first
  (`TestEngine_Update_ChangesDataAndAppendsAudit`).
- `List` never leaks a record across tenants
  (`TestEngine_List_ScopesToTenantAndEntityType`).

Also built and ran the actual `cmd/universal-core` binary against the test
database and confirmed `/healthz` returns `{"data":{"status":"ok"},"error":null}`.

`gofmt -l .`, `go vet ./...`, and `go build ./...` all clean.

## Not pushed — needs Farshid's explicit review first

Two publish-adjacent actions were **blocked by the auto-mode safety
classifier**, correctly, and were not worked around:

1. **Pushing this ADR to the public `docs` repo.** The first draft of
   ADR-0017's Context section named a real prospective customer and cited
   specific facts sourced from their internal (non-public) business
   documents — exactly the risk flagged earlier in the planning
   discussion and then contradicted when drafting the ADR. Fixed in a
   follow-up commit (genericized to "a prospective enterprise customer,"
   removed the attributed specifics) — but the push itself is left
   unpushed pending explicit sign-off, since it's a judgment call about a
   live customer relationship, not something to decide unilaterally.
2. **Creating the new public GitHub repo** for `universal-core` itself.
   Even though the code contains nothing sensitive (verified — zero
   mentions of the customer anywhere in this repo), creating brand-new
   public visibility for an unannounced product is a bigger step than
   pushing to something already public, and wasn't explicitly requested.

Both remain as local, fully committed, tested git history. Nothing has
been pushed anywhere. When reviewed: `git push` in `docs` (only after
confirming the redaction is sufficient) and `gh repo create
universaltill/universal-core --public --source=. --remote=origin` (or
`--private`, if preferred) in `universal-core`.

## Notes / what's deliberately not here yet

- No form *renderer* yet — the Form Definition schema and its validation
  exist, but nothing turns a Definition into actual HTML/HTMX output yet.
- No durable workflow execution (Postgres job queue, retries, dead-letter,
  resume) — only the synchronous in-memory executor described above.
- No prediction service (§10) or connector plugins (§11) yet.
- No base/foundation domain models (§8, the internal reference data
  model) seeded yet — the `Vendor`/`PurchaseOrder`/`POLine` definitions
  used in tests are minimal placeholders for exercising the engine, not
  the real foundation entities.
- Migration only tested against Postgres 16; not yet run against whatever
  version the eventual hosting environment uses.
- Built while Farshid was away, per his explicit "don't stop and
  continue" — worth a full look when he's back before treating any of
  this as more than a spike.
