# Development Guide (Multi-Repo)

This guide consolidates how to build, run, and test each repo in the workspace.

## Prerequisites

- Go toolchain (version varies by repo; align if possible)
  - POS: Go 1.25 (`universal-till/go.mod`)
  - Marketplace: Go 1.25.3 (`ut-market-place/go.mod`)
  - FAQ plugin: Go 1.21 (`ut-plugin-faq/go.mod`)
- Local services depending on repo configuration:
  - Marketplace may use SQLite/Postgres + optional Redis + NATS
  - POS uses SQLite (local file) and optional marketplace endpoint

## POS (universal-till)

Repo: `~/repos/unitill/universal-till`

### Build / Run
- `make build`
- `./bin/unitill-pos`

### Tests
- `go test ./...`

### Docker (optional)
- `docker compose -f docker-compose.edge.yml up --build`

### Local dev with mock marketplace
- Terminal 1: `go run scripts/mock-marketplace/main.go` (mock on `:8082`)
- Terminal 2: `./scripts/dev.sh`

### Configuration
- Uses `pos.env` or `UT_ENV_FILE` override (see `main.go` and `pos.env.example`).

## Marketplace (ut-market-place)

Repo: `~/repos/unitill/ut-market-place`

### Run server
- `go run cmd/marketplace/main.go`

### Run sync CLI (offline bundle)
- Export: `go run cmd/marketplace-sync/main.go -cmd export -merchant merchant-123 -plugins plugin-1,plugin-2 -bundle output.tar.gz`
- Import: `go run cmd/marketplace-sync/main.go -cmd import -bundle output.tar.gz`

### Verification suite
- `scripts/ci/verify.sh`
  - Runs `gofmt -l`, `go vet ./...`, `go test ./...`
  - Optional: `gosec` and `trivy` if installed
  - Runs `scripts/ci/contract_guard.sh` and a ripgrep guard

### Docs endpoints (when running)
- `/docs` (Swagger UI), `/redoc`, `/openapi.yaml`, `/healthz`, `/.well-known/marketplace-endpoints.json`, `/ui/`

## FAQ Plugin (ut-plugin-faq)

Repo: `~/repos/unitill/ut-plugin-faq`

### Build / Test
- Build: `go build -o bin/ut-faq ./src`
- Tests: `go test ./...`

### Manifest validation
- `uitill manifest validate src/manifest/manifest.json` (verify the tool name/version; may be `unitill` or a marketplace validator)

## Workspace Notes / Known Issues

- Go versions differ across repos (1.21 vs 1.25+). Consider standardizing to reduce friction.
- Plugin end-to-end testing depends on marketplace publish/install + POS plugin host wiring.
