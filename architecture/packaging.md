# Packaging & releases (P0.3, zero-touch phase A)

Status: **SHIPPED 2026-07-14 — v0.1.0 released** (review code-reviews/2026-07-14-packaging.md). "Production" for anyone but us
means installing without a Go toolchain. Today `deploy/raspberry-pi/
install.sh` builds from source on the device.

## Scope (increment 1 — prebuilt artifacts)

- **goreleaser** config in universal-till, wired to a `Release` GitHub
  Actions workflow on `v*` tags:
  - Binaries: linux amd64/arm64, windows amd64, macOS arm64
    (CGO-free — pure-Go SQLite makes cross-compiling trivial).
  - **Archives** (tar.gz/zip) bundling the binary + `web/` (templates are
    read from disk at runtime — a bare binary is not runnable) +
    `pos.env.example` + README.
  - **`.deb` packages** (arm64 for Raspberry Pi OS, amd64 for any Debian
    box) via nfpm — the real phase A deliverable:
    - Layout matches the existing convention: `/opt/unitill/bin`,
      `/opt/unitill/web`, `EnvironmentFile /opt/unitill/pos.env`
      (config-noreplace), systemd unit enabled on install.
    - postinstall: creates the `pos` system user, moves item images
      (`web/public/assets/items`) onto `/var/lib/unitill/items` behind a
      symlink so **shop item photos survive package upgrades** (the rest
      of `web/` is package-owned and refreshed by upgrades), seeds demo
      thumbs only when empty, `systemctl enable --now`.
    - `apt install ./unitill-pos_*.deb` → till on :8080 at boot.
- Windows increment 1 = the zip archive + `run-unitill.bat` (correct
  working dir, opens the browser). Proper MSI/service install is the
  follow-up (needs WiX/NSIS tooling decision).

## Later increments

Pi SD-card image (pi-gen with the .deb + kiosk preinstalled), Windows
MSI + service wrapper, macOS notarised app, auto-update channel.

## Verification

`goreleaser --snapshot` locally: archives contain binary+web; extracted
archive runs with CWD at its root (templates load, healthz 200); .deb
inspected (layout, unit, scripts) — apt install boot test on the Pi is
Farshid's hardware sign-off, same as the printer.
