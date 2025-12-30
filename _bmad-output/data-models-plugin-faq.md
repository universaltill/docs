# Data Models — Plugin FAQ (ut-plugin-faq)

Part: `plugin-faq`  
Repo: `~/repos/unitill/ut-plugin-faq`

No persistent DB schema was detected in this plugin at the current scan level.

## Observed State Handling

- Uses local cache path `data/cache` (see `src/main.go` and `src/storage` usage).
- Loads locale bundle (e.g., `en-US`) and logs bundle metadata (locale/version/RTL).

## Notes / Gaps

- Define how plugin caches and bundled content should be packaged and validated by marketplace/POS host.

