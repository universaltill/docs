# Reference

Technical contracts. These describe *exact* formats and flows — the how-to guides
link here for the authoritative detail.

| Document | Covers |
|---|---|
| [coding-standards.md](coding-standards.md) | **Enforced** rules — repository pattern, no inline SQL, naming, API/format, offline-first, i18n. |
| [code-structure.md](code-structure.md) | Where things live in each repo — POS, marketplace, plugin, infra. |
| [data-model.md](data-model.md) | Marketplace ent entities (fields + relationships) and the POS tables. |
| [plugin-manifest.md](plugin-manifest.md) | The `manifest.json` contract — every field, canonical types, entries, permissions. |
| [plugin-lifecycle.md](plugin-lifecycle.md) | The full package → publish → validate → review → sign → download → verify → install flow. |
| [release-artifact.md](release-artifact.md) | The `.tar.gz` bundle layout and checksum rules. |
| [deployment.md](deployment.md) | Live deployment topology and one-time credential/bootstrap steps. |
| [pos-acceptance-matrix.md](pos-acceptance-matrix.md) | POS capabilities (epics 2–5) mapped to the automated tests that accept them. |
