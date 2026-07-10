# 0006 — Plugin trust chain

**Status:** accepted (2026-07-06/07, proven live)

## Decision
publish (vendor upload) → structural scan → review assignment → approve =
sign canonical manifest (Ed25519, marketplace key; pubkey pinned in POS
config) → catalog → merchant approval = entitlement (self-serve for free
listings; revoked blocks re-acquire) → POS download-token → checksum +
signature verify → install. **No unverified plugin ever runs.** Signing
contract: `signing.CanonicalManifest` must mirror `plugins.Manifest`
field-for-field (guarded by cross-repo test).
