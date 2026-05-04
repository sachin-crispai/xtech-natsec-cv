# PR-003 — SIERRA Control Center: Architecture Capture

| Field | Value |
|-------|-------|
| GitHub PR | [#3](https://github.com/sachin-crispai/xtech-natsec-cv/pull/3) |
| Branch | `arch/sierra-control-center` |
| Status | **MERGED** |
| Created | 2026-05-03 |
| Merged | 2026-05-03 |

---

## Description

Requirements and architecture capture for the SIERRA secure control center in Las Vegas. Based on the whiteboard sketch from 2026-05-03. Documents a 4-tier hierarchy (VEGAS → SIERRA → TAHOE → EDGE) covering ~200 operational controllers and ~100,000 edge drone masters.

## Architecture — 4 Tiers

```
VEGAS tier    2–3 global brain centers (H100/H200, training)     ← top of hierarchy
     ↕ VPN
SIERRA zone   ~200 operational controllers (H100, mission exec)
     ├── TAHOE tier     large-lake named hubs    (3–4 per zone)
     └── Sub-tier       small-lake named nodes   (4–5 per hub)
     ↓
EDGE tier     ~100,000 drone masters (limited GPU, field)         ← leaf nodes
```

### SIERRA Core (TAHOE Tier) — ~200 nodes
- Location: inside SIERRA secure zone, Las Vegas
- GPU: H100 / H200 (training-capable)
- Hub: **TAHOE** (central), **ALMANOR** + **DONNER** as sub-controllers
- Planned: CRATER, SHASTA, MONO
- Naming convention: California lakes

### Remote / Field (VEGAS Tier)
- **mamba** (operator workstation) — access always via VPN regardless of physical location
- Role: mission monitoring, dev/test, operator workstation

### Edge (EDGE Tier) — ~100,000 nodes
- Drone masters at periphery with local swarms
- Limited GPU — inference only
- Automatic failover to backup controller on primary loss, with state sync

## Key Decisions Captured

- Node naming: California lakes (TAHOE, ALMANOR, DONNER, CRATER, SHASTA…)
- mamba = VPN-only access regardless of physical location
- EDGE failover is automatic with state sync to backup controller
- SIERRA is a hard security boundary — no inbound without VPN auth

## Open Requirements (carried to implementation)

- VPN infrastructure and certificate authority design
- EDGE failover protocol and heartbeat tuning
- State sync specification
- H100/H200 procurement and rack layout
- Power and cooling budget per SIERRA zone

## Source Files

- `docs/architecture/SIERRA-CONTROL-CENTER.md` — full requirements doc
- `docs/architecture/SIERRA-ARCHITECTURE.md` — architecture narrative
- `docs/architecture/SIERRA-ARCHITECTURE.html` — rendered view
- `docs/architecture/sierra-whiteboard-sketch.jpg` — source whiteboard photo
