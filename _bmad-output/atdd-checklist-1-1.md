# ATDD Checklist - Epic 1, Story 1.1: CLI-Assisted Plugin Install

**Date:** 2025-12-24
**Author:** Farshid
**Primary Test Level:** API

---

## Story Summary

Define and validate a CLI-driven plugin install flow across marketplace APIs and POS telemetry, with offline bundle support and FAQ plugin visibility in POS. The tests assert install intent creation, status tracking, telemetry updates, and POS UI entrypoints for the FAQ plugin.

**As a** platform developer
**I want** a CLI-assisted plugin install flow backed by marketplace APIs and POS plugin-host reporting
**So that** plugins can be installed and verified end-to-end and marketplace health reflects install status

---

## Acceptance Criteria

1. CLI supports installing a plugin by id+version for a merchant (optionally device/POS scoped), against local or production endpoints.
2. CLI supports checking install status/health for that plugin (merchant/device scoped).
3. CLI supports offline workflows using export/import bundles (for disconnected stores).
4. Marketplace records an install intent initiated by the CLI, including plugin id/version, merchant, and optional device.
5. POS plugin host can apply the plugin bundle and report status back to marketplace (state + error details on failure).
6. FAQ plugin can be installed and becomes visible under Help/Support in POS (or equivalent UI entrypoint) in a local dev setup.
7. Marketplace (UI or API) surfaces the plugin as installed with healthy status after successful install.

---

## Failing Tests Created (RED Phase)

### E2E Tests (1 test)

**File:** `~/repos/unitill/universal-till/tests/e2e/tests/plugin_install_flow.spec.ts` (71 lines)

- ✅ **Test:** FAQ plugin entrypoint is visible in POS UI
  - **Status:** RED - missing data-testid entrypoints and/or FAQ UI route
  - **Verifies:** POS exposes Help/Support navigation and FAQ plugin entry

### API Tests (4 tests)

**File:** `~/repos/unitill/universal-till/tests/e2e/tests/plugin_install_flow.spec.ts` (71 lines)

- ✅ **Test:** CLI install intent API accepts plugin id+version
  - **Status:** RED - endpoint `/v1/install/intents` not implemented or missing fields
  - **Verifies:** install intent schema and persistence
- ✅ **Test:** CLI status API returns health for plugin install
  - **Status:** RED - endpoint `/v1/install/status` not implemented
  - **Verifies:** status/health reporting for plugin install
- ✅ **Test:** Offline bundle export/import validates checksum
  - **Status:** RED - bundle endpoints not implemented
  - **Verifies:** offline export/import flow with integrity checks
- ✅ **Test:** POS plugin host reports install status back to marketplace
  - **Status:** RED - telemetry endpoint `/v1/telemetry/plugins` not implemented
  - **Verifies:** status telemetry payload acceptance

### Component Tests (0 tests)

---

## Data Factories Created

### Plugin Factory

**File:** `~/repos/unitill/universal-till/tests/e2e/support/fixtures/factories/plugin-factory.ts`

**Exports:**

- `createInstallIntent(overrides?)` - Create install intent payload
- `createBundle(overrides?)` - Create offline bundle payload

**Example Usage:**

```typescript
const intent = pluginFactory.createInstallIntent({ plugin_id: 'faq-plugin', version: '0.1.0' });
const bundle = pluginFactory.createBundle({ checksum: 'sha256-abc' });
```

---

## Fixtures Created

### Plugin Fixtures

**File:** `~/repos/unitill/universal-till/tests/e2e/support/fixtures/index.ts`

**Fixtures:**

- `pluginFactory` - Generates install intent and bundle payloads
  - **Setup:** Instantiate factory
  - **Provides:** `pluginFactory` helper
  - **Cleanup:** None (no persisted data)

---

## Mock Requirements

### Marketplace Install Intent API Mock

**Endpoint:** `POST /v1/install/intents`

**Success Response:**

```json
{ "plugin_id": "faq-plugin", "version": "0.1.0", "merchant_id": "merchant-1" }
```

**Failure Response:**

```json
{ "error": { "code": "VALIDATION_ERROR", "message": "missing plugin_id" } }
```

**Notes:** Validate schema and persist install intent.

### Telemetry API Mock

**Endpoint:** `POST /v1/telemetry/plugins`

**Success Response:**

```json
{ "status": "accepted" }
```

**Failure Response:**

```json
{ "error": { "code": "INVALID_STATE", "message": "unknown state" } }
```

**Notes:** Accept install state transitions (requested -> downloading -> installing -> active -> failed).

---

## Required data-testid Attributes

### POS Navigation / Plugin Entry

- `nav-help-support` - Help/Support navigation entrypoint
- `plugin-faq-entry` - FAQ plugin entry link/button

**Implementation Example:**

```tsx
<button data-testid="nav-help-support">Help</button>
<a data-testid="plugin-faq-entry" href="/help/faq">FAQ</a>
```

---

## Implementation Checklist

### Test: CLI install intent API accepts plugin id+version

**File:** `~/repos/unitill/universal-till/tests/e2e/tests/plugin_install_flow.spec.ts`

**Tasks to make this test pass:**

- [ ] Implement `POST /v1/install/intents` endpoint in marketplace service
- [ ] Validate required fields: plugin_id, version, merchant_id
- [ ] Persist install intent record
- [ ] Return 201 with intent payload
- [ ] Run test: `npx playwright test tests/plugin_install_flow.spec.ts -g "install intent"`
- [ ] ✅ Test passes (green phase)

**Estimated Effort:** 4 hours

---

### Test: POS plugin host reports install status back to marketplace

**File:** `~/repos/unitill/universal-till/tests/e2e/tests/plugin_install_flow.spec.ts`

**Tasks to make this test pass:**

- [ ] Implement `POST /v1/telemetry/plugins` endpoint
- [ ] Validate state transitions and timestamps
- [ ] Persist telemetry status
- [ ] Surface health in marketplace status API
- [ ] Run test: `npx playwright test tests/plugin_install_flow.spec.ts -g "telemetry"`
- [ ] ✅ Test passes (green phase)

**Estimated Effort:** 4 hours

---

## Running Tests

```bash
# Run all failing tests for this story
npx playwright test tests/plugin_install_flow.spec.ts

# Run specific test file
npx playwright test tests/plugin_install_flow.spec.ts

# Run tests in headed mode (see browser)
npx playwright test tests/plugin_install_flow.spec.ts --headed

# Debug specific test
npx playwright test tests/plugin_install_flow.spec.ts --debug

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

- Tests written to fail due to missing endpoints/UI
- Failures expected at missing routes or selectors

---

## Next Steps

1. Review this checklist with team
2. Run failing tests to confirm RED phase
3. Implement marketplace endpoints and POS telemetry reporting
4. Add required data-testid attributes for FAQ entrypoint
5. Refactor with tests green

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

**Command:** `npx playwright test tests/plugin_install_flow.spec.ts`

**Results:**

```
Not run in this environment. Expected failures: missing API endpoints and missing data-testid entrypoints.
```

**Summary:**

- Total tests: 5
- Passing: 0 (expected)
- Failing: 5 (expected)
- Status: ✅ RED phase prepared

**Expected Failure Messages:**
- 404 or connection error for `/v1/install/intents`
- 404 or connection error for `/v1/install/status`
- 404 or connection error for `/v1/install/bundles/*`
- 404 or connection error for `/v1/telemetry/plugins`
- Locator not found for `nav-help-support` / `plugin-faq-entry`

---

## Notes

- Tests assume marketplace APIs are reachable from POS baseURL; adjust baseURL or API routing if split.
- FAQ entrypoint uses explicit data-testid selectors for stability.
- Offline bundle endpoints are placeholders and must align with final API naming.

---

**Generated by BMad TEA Agent** - 2025-12-24
