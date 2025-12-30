# FAQ Plugin (Multilingual)

Sources: ut-plugin-faq/README.md and specs/001-multilingual-faq-page/*

Current state:
- Multilingual, offline-capable FAQ page plugin for POS Help/Support.
- Localized content (en-US, en-GB, fr-FR, ar-SA, fa-IR, tr-TR, es-ES, it-IT, pt-PT) with RTL support.
- Build: `go build -o bin/ut-faq ./src`
- Tests: `go test ./...`
- Manifest validate: `uitill manifest validate src/manifest/manifest.json` (verify command spelling/version).

Next:
- Validate install via marketplace + CLI + POS.
- Align manifest with marketplace/POS contracts.

Install validation (target):
- Run `marketplace-cli install --plugin ut-faq@<version> --merchant <test-merchant> --device <pos-id> --env local --endpoint http://localhost:8081`
- Expect: FAQ entry appears under Help/Support in POS; `marketplace-cli status` shows healthy.
