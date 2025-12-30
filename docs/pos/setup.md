# POS Setup

Sources:
- universal-till/README.md (quick start)
- universal-till/docs/marketplace-config.md (env config)
- pos.env.example/pos.env.dev references

## Binary/Run
- Build/run: `./bin/unitill-pos` (see repo Makefile/scripts).
- Env file: `pos.env` (production) or `pos.env.dev` for development via `UT_ENV_FILE=pos.env.dev ./bin/unitill-pos` or `./scripts/dev.sh`.
- Go version: 1.21+ (per repo badge).

## Marketplace Endpoint Config
Set `UT_MARKETPLACE_ENDPOINT_URL` to target:
- Production: `https://marketplace.universaltill.com`
- Local/self-hosted: `http://localhost:8081`
- Mock: `http://localhost:8082`

Client auth examples (from dev sample):
```
UT_MARKETPLACE_CLIENT_ID=pos-client
UT_MARKETPLACE_CLIENT_SECRET=dev-secret
```

## Files
- `pos.env` (created on install) / `pos.env.dev` (dev override).
- Consider adding `pos.env.test` for automated tests (not yet present).

## Next
- Document plugin host expectations (install/update/remove).
- Add UI/dev server steps and hardware dependencies.
- Add POS/back office separation notes for LAN vs standalone vs cloud.
