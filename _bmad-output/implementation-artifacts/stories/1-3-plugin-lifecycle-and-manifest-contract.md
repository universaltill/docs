# Story 1.3: Plugin Lifecycle + Manifest Contract (Docs + Acceptance)

Status: ready-for-dev

## Story

As a platform architect,
I want a clear, shared definition of the plugin lifecycle and manifest contract across marketplace and POS,
so that plugin install/update/remove and validation behave consistently and can be implemented without guessing.

## Acceptance Criteria

1. `docs/plugins/lifecycle.md` describes the end-to-end lifecycle: publish → install intent → delivery → POS apply → telemetry/status → update/remove.
2. `docs/plugins/manifest.md` documents a minimal required schema and links to authoritative contracts in the repos.
3. The lifecycle doc defines standard install states and required telemetry fields.
4. The docs explicitly cover offline/disconnected operation (bundle export/import, caching, retry behavior).
5. The docs call out compatibility/versioning expectations and how validation errors are surfaced (CLI + API + POS).

## Tasks / Subtasks

- [ ] Consolidate lifecycle flow and acceptance (AC: 1, 3, 4)
  - [ ] Define states and transitions
  - [ ] Define telemetry payload fields
  - [ ] Document offline bundle workflows
- [ ] Consolidate manifest contract (AC: 2, 5)
  - [ ] Link to POS contracts (plugin-manifest) and marketplace contracts (compatibility/versioning)
  - [ ] Document validation error surface points

## Dev Notes

- Primary docs to update:
  - `docs/plugins/lifecycle.md`
  - `docs/plugins/manifest.md`
- Contract sources to link and reconcile:
  - POS plugin manifest (in `universal-till/specs/.../contracts`)
  - Marketplace compatibility/versioning contracts (`ut-market-place/specs/.../contracts`)
  - Plugin-specific manifests (e.g., FAQ plugin contracts)

### References

- `docs/plugins/lifecycle.md`
- `docs/plugins/manifest.md`
- `docs/marketplace/cli.md`
- `docs/marketplace/api.md`
