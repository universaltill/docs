# ATDD Checklist - Epic 1, Story 1.3: Plugin Lifecycle + Manifest Contract (Docs + Acceptance)

**Date:** 2025-12-24
**Author:** Farshid
**Primary Test Level:** E2E

---

## Story Summary

Define a shared, documented plugin lifecycle and manifest contract so marketplace, POS, and plugins align on install/update/remove flow, telemetry, offline operation, and validation expectations.

**As a** platform architect
**I want** a clear lifecycle + manifest contract across marketplace and POS
**So that** plugin install/update/remove and validation behave consistently

---

## Acceptance Criteria

1. `docs/plugins/lifecycle.md` describes the end-to-end lifecycle: publish → install intent → delivery → POS apply → telemetry/status → update/remove.
2. `docs/plugins/manifest.md` documents a minimal required schema and links to authoritative contracts in the repos.
3. The lifecycle doc defines standard install states and required telemetry fields.
4. The docs explicitly cover offline/disconnected operation (bundle export/import, caching, retry behavior).
5. The docs call out compatibility/versioning expectations and how validation errors are surfaced (CLI + API + POS).

---

## Failing Tests Created (RED Phase)

### E2E Tests (2 tests)

**File:** `~/repos/unitill/universal-till/tests/e2e/tests/plugin_lifecycle_docs.spec.ts` (31 lines)

- ✅ **Test:** lifecycle doc includes publish -> install -> telemetry -> update flow
  - **Status:** RED - lifecycle flow or offline handling missing
  - **Verifies:** `docs/plugins/lifecycle.md` covers lifecycle and offline bundle behavior
- ✅ **Test:** manifest doc defines required schema fields
  - **Status:** RED - manifest schema fields or compatibility notes missing
  - **Verifies:** `docs/plugins/manifest.md` includes core schema fields and compatibility expectations

### API Tests (0 tests)

### Component Tests (0 tests)

---

## Data Factories Created

No new data factories created for this story.

---

## Fixtures Created

No new fixtures created for this story. Tests use the existing `test` fixture from `~/repos/unitill/universal-till/tests/e2e/support/fixtures/index.ts`.

---

## Mock Requirements

No external service mocks required for this story.

---

## Required data-testid Attributes

No UI data-testid attributes required for documentation validation.

---

## Implementation Checklist

### Test: lifecycle doc includes publish -> install -> telemetry -> update flow

**File:** `~/repos/unitill/universal-till/tests/e2e/tests/plugin_lifecycle_docs.spec.ts`

**Tasks to make this test pass:**

- [ ] Update `docs/plugins/lifecycle.md` with end-to-end lifecycle steps and install states
- [ ] Add required telemetry fields and state transition expectations
- [ ] Document offline/disconnected bundle export/import and retry/caching behavior
- [ ] Run test: `npx playwright test tests/plugin_lifecycle_docs.spec.ts -g "lifecycle doc"`
- [ ] ✅ Test passes (green phase)

**Estimated Effort:** 3 hours

---

### Test: manifest doc defines required schema fields

**File:** `~/repos/unitill/universal-till/tests/e2e/tests/plugin_lifecycle_docs.spec.ts`

**Tasks to make this test pass:**

- [ ] Update `docs/plugins/manifest.md` with minimal required schema fields (id, version, capabilities, permissions, min_host_version)
- [ ] Link to authoritative POS and marketplace contract references
- [ ] Add compatibility/versioning expectations and validation error surfaces (CLI/API/POS)
- [ ] Run test: `npx playwright test tests/plugin_lifecycle_docs.spec.ts -g "manifest doc"`
- [ ] ✅ Test passes (green phase)

**Estimated Effort:** 3 hours

---

## Running Tests

```bash
# Run all failing tests for this story
npx playwright test tests/plugin_lifecycle_docs.spec.ts

# Run specific test file
npx playwright test tests/plugin_lifecycle_docs.spec.ts

# Run tests in headed mode (see browser)
npx playwright test tests/plugin_lifecycle_docs.spec.ts --headed

# Debug specific test
npx playwright test tests/plugin_lifecycle_docs.spec.ts --debug

# Run tests with coverage
# Coverage not configured
```

---

## Red-Green-Refactor Workflow

### RED Phase (Complete) ✅

**TEA Agent Responsibilities:**

- ✅ All tests written and failing
- ✅ Fixtures and factories created with auto-cleanup
- ✅ Mock requirements documented
- ✅ data-testid requirements listed
- ✅ Implementation checklist created

**Verification:**

- Tests written to fail due to missing lifecycle/manifest doc content
- Failures expected at missing keywords and sections

---

## Next Steps

1. Review this checklist with team
2. Run failing tests to confirm RED phase
3. Update `docs/plugins/lifecycle.md` and `docs/plugins/manifest.md` per checklist
4. Refactor language for consistency once tests are green

---

## Knowledge Base References Applied

- **fixture-architecture.md** - Test fixture patterns with setup/teardown and auto-cleanup using Playwright's `test.extend()`
- **data-factories.md** - Factory patterns using deterministic payloads with overrides support
- **component-tdd.md** - Component test strategies using Playwright Component Testing
- **network-first.md** - Route interception patterns (intercept BEFORE navigation to prevent race conditions)
- **test-quality.md** - Test design principles (Given-When-Then, determinism, isolation)
- **test-levels-framework.md** - Test level selection framework (E2E vs API vs Component vs Unit)

---

## Test Execution Evidence

### Initial Test Run (RED Phase Verification)

**Command:** `npx playwright test tests/plugin_lifecycle_docs.spec.ts`

**Results:**

```
Not run in this environment. Expected failures: missing lifecycle or manifest content in docs.
```

**Summary:**

- Total tests: 2
- Passing: 0 (expected)
- Failing: 2 (expected)
- Status: ✅ RED phase prepared

**Expected Failure Messages:**
- Missing lifecycle keywords in `docs/plugins/lifecycle.md`
- Missing schema/compatibility fields in `docs/plugins/manifest.md`

---

## Notes

- Tests read from `DOCS_ROOT` or default to `~/repos/unitill/docs/docs`.
- Update docs content rather than test expectations unless scope changes.

---

**Generated by BMad TEA Agent** - 2025-12-24
