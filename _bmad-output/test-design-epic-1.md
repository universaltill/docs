# Test Design: Epic 1 - Plugin Install Flow

**Date:** 2025-12-24
**Author:** Farshid
**Status:** Draft

---

## Executive Summary

**Scope:** full test design for Epic 1 (CLI + Marketplace + POS plugin install flow) covering stories 1.1-1.4.

**Risk Summary:**

- Total risks identified: 9
- High-priority risks (>=6): 4
- Critical categories: TECH, SEC, OPS

**Coverage Summary:**

- P0 scenarios: 8 (16 hours)
- P1 scenarios: 12 (12 hours)
- P2/P3 scenarios: 16 (6.5 hours)
- **Total effort**: 34.5 hours (~4.5 days)

---

## Risk Assessment

### High-Priority Risks (Score >=6)

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner | Timeline |
| ------- | -------- | ----------- | ----------- | ------ | ----- | ---------- | ----- | -------- |
| R-001 | TECH | CLI -> marketplace -> POS install flow fails due to contract mismatch or missing fields | 2 | 3 | 6 | Contract tests + integration E2E install with schema validation | QA | 2025-12-24 |
| R-002 | SEC | Unsigned or tampered plugin bundle accepted in offline import | 2 | 3 | 6 | Signature/checksum validation tests + negative cases | QA | 2025-12-24 |
| R-003 | OPS | Install telemetry/status not reported or stuck, marketplace shows stale health | 2 | 3 | 6 | Telemetry API tests + retry/backoff validation | QA | 2025-12-24 |
| R-004 | DATA | Offline bundle import/export yields corrupted or wrong version installed | 2 | 3 | 6 | Bundle integrity tests, version pinning, rollback tests | QA | 2025-12-24 |

### Medium-Priority Risks (Score 3-4)

| Risk ID | Category | Description | Probability | Impact | Score | Mitigation | Owner |
| ------- | -------- | ----------- | ----------- | ------ | ----- | ---------- | ----- |
| R-005 | BUS | Installed plugin not visible at POS entrypoint (FAQ page missing) | 2 | 2 | 4 | POS UI entrypoint checks + plugin surface smoke | QA |
| R-006 | TECH | CLI status output inconsistent or missing error codes | 2 | 2 | 4 | CLI contract tests (golden output) | QA |
| R-007 | OPS | Offline bundle workflow lacks retry/recovery, leaving plugin in indeterminate state | 2 | 2 | 4 | Offline flow tests with simulated failure + resume | QA |
| R-008 | DATA | Manifest validation misses required fields or version compatibility | 1 | 3 | 3 | Manifest schema validation tests (unit + integration) | QA |

### Low-Priority Risks (Score 1-2)

| Risk ID | Category | Description | Probability | Impact | Score | Action |
| ------- | -------- | ----------- | ----------- | ------ | ----- | ------ |
| R-009 | BUS | Docs hub links or legacy labeling drift | 1 | 2 | 2 | Monitor | 

### Risk Category Legend

- **TECH**: Technical/Architecture (flaws, integration, scalability)
- **SEC**: Security (access controls, auth, data exposure)
- **PERF**: Performance (SLA violations, degradation, resource limits)
- **DATA**: Data Integrity (loss, corruption, inconsistency)
- **BUS**: Business Impact (UX harm, logic errors, revenue)
- **OPS**: Operations (deployment, config, monitoring)

---

## Test Coverage Plan

### P0 (Critical) - Run on every commit

**Criteria**: Blocks core journey + High risk (>=6) + No workaround

| Requirement | Test Level | Risk Link | Test Count | Owner | Notes |
| ----------- | ---------- | --------- | ---------- | ----- | ----- |
| CLI install by plugin id+version, marketplace records install intent | API | R-001 | 2 | QA | Verify request/response schema + persisted intent |
| POS applies bundle and reports status to marketplace | Integration | R-001 | 2 | QA | Validate state transitions + telemetry payload |
| Offline bundle export/import validates signature/checksum | Integration | R-002 | 2 | QA | Negative tests for tampering |
| Marketplace reflects healthy installed status | E2E | R-003 | 2 | QA | End-to-end flow with FAQ plugin |

**Total P0**: 8 tests, 16 hours

### P1 (High) - Run on PR to main

**Criteria**: Important features + Medium risk (3-4) + Common workflows

| Requirement | Test Level | Risk Link | Test Count | Owner | Notes |
| ----------- | ---------- | --------- | ---------- | ----- | ----- |
| CLI status command output format, error codes, timestamps | Unit | R-006 | 3 | QA | Golden output snapshots |
| Plugin becomes visible under Help/Support in POS | Component | R-005 | 3 | QA | UI surface smoke (no layout regressions) |
| Offline install resume/retry after failure | Integration | R-007 | 2 | QA | Simulated network drop |
| Manifest validation rejects incompatible versions | Unit | R-008 | 4 | QA | Schema + compatibility tests |

**Total P1**: 12 tests, 12 hours

### P2 (Medium) - Run nightly/weekly

**Criteria**: Secondary features + Low risk (1-2) + Edge cases

| Requirement | Test Level | Risk Link | Test Count | Owner | Notes |
| ----------- | ---------- | --------- | ---------- | ----- | ----- |
| Marketplace UI/API shows installed/healthy status | E2E | R-003 | 4 | QA | UI smoke with status transitions |
| CLI install against multiple endpoints (local/prod config) | Unit | R-006 | 4 | QA | Config matrix |
| Docs hub link integrity + legacy labeling | Unit | R-009 | 2 | QA | Link check + legacy marker check |

**Total P2**: 10 tests, 5 hours

### P3 (Low) - Run on-demand

**Criteria**: Nice-to-have + Exploratory + Performance benchmarks

| Requirement | Test Level | Test Count | Owner | Notes |
| ----------- | ---------- | ---------- | ----- | ----- |
| Long-running install telemetry backlog flush | Integration | 2 | QA | Buffer replay edge case |
| CLI help/usage formatting | Unit | 4 | QA | Cosmetic only |

**Total P3**: 6 tests, 1.5 hours

---

## Execution Order

### Smoke Tests (<5 min)

**Purpose**: Fast feedback, catch build-breaking issues

- [ ] CLI install happy path to marketplace intent (API)
- [ ] POS applies bundle, reports status (Integration)
- [ ] Marketplace shows installed healthy (API/UI)

**Total**: 3 scenarios

### P0 Tests (<10 min)

**Purpose**: Critical path validation

- [ ] CLI install intent persists with correct fields
- [ ] Offline bundle import rejects tampered bundle
- [ ] POS telemetry transitions to active
- [ ] Marketplace installed health is green

**Total**: 8 scenarios

### P1 Tests (<30 min)

**Purpose**: Important feature coverage

- [ ] CLI status output contract
- [ ] POS FAQ entrypoint visible
- [ ] Offline retry/resume
- [ ] Manifest compatibility validation

**Total**: 12 scenarios

### P2/P3 Tests (<60 min)

**Purpose**: Full regression coverage

- [ ] Endpoint matrix config
- [ ] UI status smoke
- [ ] Docs hub link integrity
- [ ] Telemetry backlog flush

**Total**: 16 scenarios

---

## Resource Estimates

### Test Development Effort

| Priority | Count | Hours/Test | Total Hours | Notes |
| -------- | ----- | ---------- | ----------- | ----- |
| P0 | 8 | 2.0 | 16 | Contract + integration coverage |
| P1 | 12 | 1.0 | 12 | CLI + UI smoke + schema |
| P2 | 10 | 0.5 | 5 | Mostly automation/verification |
| P3 | 6 | 0.25 | 1.5 | Cosmetic and edge cases |
| **Total** | **36** | **-** | **34.5** | **~4.5 days** |

### Prerequisites

**Test Data:**

- Merchant/device fixtures with deterministic IDs
- Plugin bundle fixtures (valid + tampered + incompatible versions)
- Marketplace install intent records for status checks

**Tooling:**

- Playwright for UI smoke (per official docs)
- Pact (or equivalent) for marketplace/CLI contract verification
- Link checker for docs hub consistency

**Environment:**

- Local marketplace + POS + plugin host running
- CLI wired to local endpoints and auth configured
- Offline simulation harness (network block / bundle import/export)

---

## Quality Gate Criteria

### Pass/Fail Thresholds

- **P0 pass rate**: 100% (no exceptions)
- **P1 pass rate**: >=95% (waivers required for failures)
- **P2/P3 pass rate**: >=90% (informational)
- **High-risk mitigations**: 100% complete or approved waivers

### Coverage Targets

- **Critical paths**: >=80%
- **Security scenarios**: 100%
- **Business logic**: >=70%
- **Edge cases**: >=50%

### Non-Negotiable Requirements

- [ ] All P0 tests pass
- [ ] No high-risk (>=6) items unmitigated
- [ ] Security tests (SEC category) pass 100%
- [ ] Offline bundle integrity validated

---

## Mitigation Plans

### R-001: Contract mismatch across CLI/Marketplace/POS (Score: 6)

**Mitigation Strategy:** Pact contract tests + schema validation at CLI and marketplace boundary; integration tests for install intent + telemetry.
**Owner:** QA
**Timeline:** 2025-12-24
**Status:** Planned
**Verification:** Contract test suite green + E2E install flow passes.

### R-002: Unsigned/tampered bundle accepted (Score: 6)

**Mitigation Strategy:** Negative tests with altered checksum/signature; enforce rejection in CLI and POS; verify marketplace status shows failure with error.
**Owner:** QA
**Timeline:** 2025-12-24
**Status:** Planned
**Verification:** Tampered bundle test fails install and logs correct error code.

### R-003: Telemetry/status stuck (Score: 6)

**Mitigation Strategy:** API tests for status update endpoints; simulate retries and verify final state and timestamps.
**Owner:** QA
**Timeline:** 2025-12-24
**Status:** Planned
**Verification:** Status transitions to active within retry window; marketplace shows healthy.

### R-004: Offline bundle corruption/version drift (Score: 6)

**Mitigation Strategy:** Bundle export/import tests with version pinning; rollback tests for incompatible version.
**Owner:** QA
**Timeline:** 2025-12-24
**Status:** Planned
**Verification:** Import rejects wrong version; rollback restores previous.

---

## Assumptions and Dependencies

### Assumptions

1. CLI can target local marketplace endpoints with valid auth.
2. POS plugin host supports telemetry state machine (requested -> downloading -> installing -> active -> failed).
3. FAQ plugin bundle available for local dev validation.

### Dependencies

1. Marketplace install intent + status APIs implemented and stable.
2. POS plugin host can ingest bundles and report status.
3. Docs hub structure exists in `~/repos/unitill/docs/docs/`.

### Risks to Plan

- **Risk**: Multi-repo coordination delays changes in marketplace/POS/plugin.
  - **Impact**: High risk items remain unmitigated.
  - **Contingency**: Gate on contract tests + stubs until repos converge.

---

## Approval

**Test Design Approved By:**

- [ ] Product Manager: {name} Date: {date}
- [ ] Tech Lead: {name} Date: {date}
- [ ] QA Lead: {name} Date: {date}

**Comments:**

---

---

---

## Appendix

### Knowledge Base References

- `risk-governance.md` - Risk classification framework
- `probability-impact.md` - Risk scoring methodology
- `test-levels-framework.md` - Test level selection
- `test-priorities-matrix.md` - P0-P3 prioritization
- `test-quality.md` - DoD and determinism requirements

### Related Documents

- PRD: ~/repos/unitill/docs/_bmad-output/prd.md
- Epic: ~/repos/unitill/docs/_bmad-output/implementation-artifacts/stories/epic-1-plugin-install-flow.md
- Architecture: ~/repos/unitill/docs/_bmad-output/architecture.md
- Tech Spec: (none)

---

**Generated by**: BMad TEA Agent - Test Architect Module
**Workflow**: `_bmad/bmm/testarch/test-design`
**Version**: 4.0 (BMad v6)
