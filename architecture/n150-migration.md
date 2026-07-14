# Homelab → Intel N150 migration + Pis become tills (plan)

Status: **planned 2026-07-14, waiting for hardware** (Farshid: bought two
Intel N150 mini-PCs — 32 GB/1 TB and 16 GB/1 TB — "move the cluster to
these computers and get the Raspberry Pis off to make the till station
with them; we need to generate the right image for the new computers as
well").

## Phase 1 — cluster migration (when the N150s arrive)

1. **OS**: Debian/Ubuntu Server on both (amd64). The homelab-k8s Ansible
   playbooks (prepare-nodes → storage → k3s → ArgoCD bootstrap) already
   automate the cluster build — extend the inventory for the amd64 nodes;
   the playbooks were written for Pis, so expect small fixes (no
   argon/eeprom steps, different storage device names).
2. **Join, then drain**: add the N150s as nodes to the EXISTING cluster,
   move workloads (delete pods / adjust nodeSelectors: `ram-tier=high` →
   the 32 GB N150), migrate PVCs (local-path volumes must be copied —
   marketplace Postgres + Ollama models; use the marketplace's KV-backed
   secrets + fresh model pull rather than byte-copies where easier), then
   remove the Pi nodes. ArgoCD reconciles everything else.
3. **Image amd64 win**: everything we deploy is multi-arch already
   (marketplace image is built arm64 today — flip the CI build to
   amd64/multi-arch; ollama/ollama is multi-arch).
4. **Ollama gets real**: on the 32 GB N150, `llama3.2-vision` becomes
   viable → camera identify can finally point at the homelab; bigger ask
   models too. Update the AI plugin settings guidance.

## Phase 2 — Pis become till stations

- This is **zero-touch phase A's Pi image**, now with a concrete customer:
  build a flashable SD image (pi-gen) with the released **arm64 `.deb`**
  preinstalled + kiosk autostart (deploy/raspberry-pi units) + first-boot
  wizard on screen. Flash, boot, sell.
- The N150 tills note: "the right image for the new computers as well" —
  for amd64 till stations the same recipe is a Debian preseed/autoinstall
  ISO carrying the **amd64 `.deb`** + kiosk; both images are thin wrappers
  around the packages we already release (v0.1.0+).

## Order

Hardware arrives → phase 1 (cluster) → phase 2 Pi image (pi-gen) →
amd64 autoinstall ISO. Cluster migration is a supervised session with
Farshid (node access, DNS/MetalLB IPs unchanged so
*.home.taskrunnertech.co.uk keeps working).
