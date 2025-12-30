# API Contracts — Plugin FAQ (ut-plugin-faq)

Part: `plugin-faq`  
Repo: `~/repos/unitill/ut-plugin-faq`  
Entry point: `src/main.go`

This plugin currently does **not** expose HTTP/gRPC endpoints. It is a Go build artifact intended to be installed into the POS plugin host.

## Plugin Entry / UI Route

- The plugin registers a navigation entry pointing to route: `/plugin/faq` (see `src/main.go`).
- This is currently a placeholder “until wired to the POS plugin SDK”.

## Notes / Gaps

- Define the plugin SDK contract and how the POS host routes `/plugin/*` paths to plugin handlers.
- Align manifest schema and entrypoint wiring with POS plugin host and marketplace packaging rules.

