# Project Structure (Multi-Repo Workspace)

**Scan Root:** `~/repos/unitill`  
**Documentation Home:** `~/repos/unitill/docs` (all centralized docs live here)

## Repository Type

This workspace is best treated as **multi-part / multi-repo**:

- The “product” is split across multiple Go repositories (POS, marketplace, plugins).
- The `docs/` repo is the single documentation source of truth and BMAD output location.

## Detected Parts (by folder)

### 1) docs (documentation hub)

- Path: `~/repos/unitill/docs`
- Purpose: central docs and BMAD artifacts (not a Go service itself)

### 2) universal-till (POS)

- Path: `~/repos/unitill/universal-till`
- Indicators: `go.mod`
- Likely type: backend/service (Go monorepo-style layout with `cmd/`, `internal/`, etc.)

### 3) ut-market-place (plugin marketplace)

- Path: `~/repos/unitill/ut-market-place`
- Indicators: `go.mod`, `cmd/`
- Likely type: backend/service + CLI components (Go)

### 4) ut-plugin-faq (sample plugin)

- Path: `~/repos/unitill/ut-plugin-faq`
- Indicators: `go.mod`, `src/`, `specs/`
- Likely type: Go plugin project (packaged artifact consumed by POS/marketplace)

### Optional/Non-core

- `website/` (static site) — not included as a primary part in this scan unless requested.
- `images/`, `some_images/` — assets.
