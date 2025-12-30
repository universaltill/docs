# Project Documentation Index — Universal Till (Multi-Repo)

This index is the primary entry point for AI-assisted development. It links to all generated documentation and key project artifacts.

## Project Overview

- **Type:** Multi-part / multi-repo workspace
- **Scan Root:** `~/repos/unitill`
- **Documentation Home:** `~/repos/unitill/docs`
- **Primary Language:** Go
- **Core Repos:** POS (`universal-till`), marketplace (`ut-market-place`), plugins (e.g., `ut-plugin-faq`)

## Quick Reference (by part)

### POS (`universal-till`)
- **Role:** POS host (offline-first)
- **Go:** 1.25
- **Docs:** `architecture-pos.md`, `api-contracts-pos.md`, `data-models-pos.md`

### Marketplace (`ut-market-place`)
- **Role:** Plugin marketplace service + sync CLI
- **Go:** 1.25.3
- **Docs:** `architecture-marketplace.md`, `api-contracts-marketplace.md`, `data-models-marketplace.md`

### Plugin FAQ (`ut-plugin-faq`)
- **Role:** Sample UI plugin for validation
- **Go:** 1.21
- **Docs:** `architecture-plugin-faq.md`, `api-contracts-plugin-faq.md`, `data-models-plugin-faq.md`

## Generated Documentation

- [Project Overview](./project-overview.md)
- [Project Structure](./project-structure.md)
- [Project Parts Metadata](./project-parts-metadata.md)
- [Technology Stack](./technology-stack.md)
- [Architecture Patterns (high-level)](./architecture-patterns.md)
- [Source Tree Analysis](./source-tree-analysis.md)
- [Development Guide](./development-guide.md)
- [Integration Architecture](./integration-architecture.md)
- [Supporting Documentation Summary](./supporting-documentation.md)
- [Project Parts JSON](./project-parts.json)

### Architecture (per part)
- [POS Architecture](./architecture-pos.md)
- [Marketplace Architecture](./architecture-marketplace.md)
- [FAQ Plugin Architecture](./architecture-plugin-faq.md)

### API Contracts (per part)
- [POS API Contracts](./api-contracts-pos.md)
- [Marketplace API Contracts](./api-contracts-marketplace.md)
- [FAQ Plugin API Contracts](./api-contracts-plugin-faq.md)

### Data Models (per part)
- [POS Data Models](./data-models-pos.md)
- [Marketplace Data Models](./data-models-marketplace.md)
- [FAQ Plugin Data Models](./data-models-plugin-faq.md)

### Component Inventories
- [POS Component Inventory](./component-inventory-pos.md)
- [Marketplace Component Inventory](./component-inventory-marketplace.md)
- [FAQ Plugin Component Inventory](./component-inventory-plugin-faq.md)

### Comprehensive Analyses
- [POS Comprehensive Analysis](./comprehensive-analysis-pos.md)
- [Marketplace Comprehensive Analysis](./comprehensive-analysis-marketplace.md)
- [FAQ Plugin Comprehensive Analysis](./comprehensive-analysis-plugin-faq.md)

## Existing Documentation (Source Inventory)

- [Existing Documentation Inventory](./existing-documentation-inventory.md)
- [User-Provided Context](./user-provided-context.md)

## Product Artifacts (BMAD)

These are not part of the “document project” scan outputs, but are key planning artifacts for BMAD workflows:
- Product brief: `../_bmad-output/analysis/product-brief-docs-2025-12-17T10-42-42Z.md`
- Brainstorming session: `../_bmad-output/analysis/brainstorming-session-2025-12-17T00-05-15Z.md`
- Research outputs: `../_bmad-output/analysis/research/`

## Getting Started (Developer)

Start here:
- Read `development-guide.md`
- Run POS: `make build && ./bin/unitill-pos` (POS repo)
- Run marketplace: `go run cmd/marketplace/main.go` (marketplace repo)
- Validate plugin: `go build -o bin/ut-faq ./src` (plugin repo)

## Notes / Known Gaps

- Marketplace telemetry handler exists but route registration is marked TODO; confirm canonical endpoint for POS status reporting.
- Align POS marketplace client endpoint paths with marketplace server (download ack / telemetry / revocations).
- Go versions differ across repos; consider standardizing.
