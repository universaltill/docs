# Technology Stack (per part)

This is a multi-repo workspace. The primary implementation is in Go, split across POS, marketplace, and plugins.

## POS (`universal-till`)

- **Module:** `github.com/universaltill/universal-till`
- **Go:** `1.25` (from `go.mod`)
- **Storage:** SQLite via `modernc.org/sqlite` (from `go.mod`)
- **Config:** `.env` support via `github.com/joho/godotenv`
- **UI:** HTML/HTMX patterns appear in specs and server pages (see POS specs and `internal/pages/*` references to HTMX)

## Marketplace (`ut-market-place`)

- **Module:** `github.com/universaltill/ut-market-place`
- **Go:** `1.25.3` (from `go.mod`)
- **DB/ORM:** `entgo.io/ent` plus database drivers (`github.com/lib/pq`, `github.com/mattn/go-sqlite3`)
- **HTTP routing:** `github.com/go-chi/chi/v5`
- **Auth:** JWT via `github.com/golang-jwt/jwt/v5`
- **API:** gRPC + gRPC-Gateway (`google.golang.org/grpc`, `github.com/grpc-ecosystem/grpc-gateway/v2`)
- **Messaging:** NATS (`github.com/nats-io/nats.go`)
- **Cache/queues:** Redis (`github.com/redis/go-redis/v9`) and local test redis (`github.com/alicebob/miniredis/v2`)
- **Observability:** Prometheus + OpenTelemetry (`github.com/prometheus/client_golang`, `go.opentelemetry.io/otel/*`)
- **Cloud SDK:** `gocloud.dev` (portable cloud abstractions)
- **I18n:** `golang.org/x/text`

## Plugin: FAQ (`ut-plugin-faq`)

- **Module:** `ut-plugin-faq`
- **Go:** `1.21` (from `go.mod`)
- **Notes:** Plugin is a separate Go build artifact; detailed dependencies not yet declared in `go.mod` (currently empty require block).

## Docs Hub (`docs`)

- BMAD workflow configuration, product brief, research outputs, and centralized documentation in `docs/`.
