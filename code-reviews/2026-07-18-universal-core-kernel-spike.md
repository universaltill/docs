# Code review — Universal Core kernel spike (first increment)

Date: 2026-07-18 · Repo: universal-core (new) · Branch: main
Spec: `adr/0017-universal-erp-metadata-kernel.md`, rollout §1.

## What shipped

New repo `universal-core` (public, `github.com/universaltill/universal-core`,
AGPLv3), scaffolded to match `universal-till`'s conventions (CLAUDE.md,
repository-pattern rule, module layout). First vertical slice of the
kernel spike from ADR-0017's rollout plan:

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

## Notes / what's deliberately not here yet

- No Form Definition renderer (§6, including master-detail) yet — next
  increment.
- No workflow/event engine (§9), prediction service (§10), or connector
  plugins (§11) yet.
- No base/foundation domain models (§8,
  `unitill/erp/reference-data-model.md`) seeded yet — the `Vendor`
  definition used in tests is a minimal placeholder for exercising the
  engine, not the real foundation entity.
- Migration only tested against Postgres 16; not yet run against whatever
  version the eventual hosting environment uses.
- Repo created and pushed while Farshid was away, per his explicit
  "don't stop and continue" — worth a look when he's back before treating
  any of this as more than a spike.
