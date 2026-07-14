# Review — release packaging + v0.1.0 (P0.3, zero-touch phase A increment 1)

Date: 2026-07-14 · Repo: universal-till · Spec: `architecture/packaging.md`
(written first). Third task off the production roadmap — and the first
public release: **v0.1.0 is live on GitHub with 7 assets.**

## What shipped

- `.goreleaser.yaml`: CGO-free cross-builds (pure-Go SQLite) for linux
  amd64/arm64, windows amd64, darwin arm64. Archives bundle **binary +
  `web/`** (templates/locales/assets load from disk — a bare binary
  doesn't run) + `pos.env.example` + `run-unitill.bat` (Windows).
- **`.deb` packages** (arm64 = Raspberry Pi OS 64-bit, amd64): binary to
  `/opt/unitill/bin`, web tree, systemd unit, `pos.env` as
  config-noreplace. postinstall: `pos` system user, writable dirs, and
  the important bit — **item photos survive upgrades**: `web/public/
  assets/items` is moved to `/var/lib/unitill/items` behind a symlink
  (shipped demo thumbs seed only an empty store), because the rest of
  `web/` is package-owned and refreshed on upgrade. preremove stops the
  service; data is never deleted by the package.
- `.github/workflows/release.yml`: v* tag → `go test ./...` gates →
  goreleaser publishes. README Quick Start rewritten (the old wget-a-
  bare-binary instructions could never have worked).

## Verification

- `goreleaser release --snapshot`: extracted darwin bundle **boots from
  the archive dir** (healthz 200, first-boot wizard renders — proves the
  bundle is complete); `.deb` inspected via ar/tar: layout, unit, config,
  postinst/prerm present, arm64 control fields correct.
- **Real pipeline proven**: tag `v0.1.0` pushed → workflow green →
  release live with linux tar.gz+deb (both arches), windows zip, macOS
  tar.gz, checksums.
- ⚠️ Hardware sign-off: `sudo apt install ./unitill-pos_0.1.0_linux_arm64.deb`
  boot test on the Pi is Farshid's (same list as the printer test).

## Follow-ups (spec'd)

Windows MSI/service wrapper, Pi SD-card image with kiosk preinstalled
(pi-gen + this .deb), auto-update channel, version stamped into the
binary (`--version` flag / settings page display).
