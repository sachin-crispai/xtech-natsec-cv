# PR-004 — Secure Access to the Control Center

| Field | Value |
|-------|-------|
| GitHub PR | #4 (not yet opened) |
| Branch | `feature/secure-vpn-access` |
| Status | **DRAFT** |
| Target branch | `main` |
| Owner | Sachin Naik |
| Source | Whiteboard sketches — `docs/prs/pr-004/capture/` (IMG_0215–IMG_0220) |

---

## Problem Statement

SIERRA is a secure operational zone but currently has no formal VPN infrastructure
for remote operators and demo participants. Operators (KEN, SPECTRO, mamba) need
authenticated, encrypted access from outside the zone. Prospective customers and
hackathon judges need a controlled demo environment inside SIERRA without exposing
the full control center. Two distinct access paths are needed: one for operators,
one for demos.

---

## What the Whiteboard Shows

```
[KEN]  ──┐
          ├──→  VPN Server  ──→  MAMBA ──→  SIERRA
[SPECTRO]─┘         ↑              ↑
                     │         DemoGateway (pink — controlled demo zone)
[Demo] ─────→  VPN Server ─────────┘
               (separate)
```

**Nodes visible in IMG_0216–IMG_0220 (labeled PR #004):**

| Node | Type | Notes |
|------|------|-------|
| **VPN Server** | New infrastructure | Authenticates KEN, SPECTRO, mamba — operator path |
| **KEN** | External operator | Connects to SIERRA via VPN Server |
| **SPECTRO** | External operator / sensor node | New — connects via VPN Server |
| **DemoGateway** | New SIERRA component | Circled in pink — controlled access layer for demos inside SIERRA |
| **Demo** | Demo environment | Connects via a separate VPN Server (bottom path) |
| **MAMBA** | Operator node | Entry point into SIERRA from VPN |

---

## Proposed Solution

Two VPN access paths into SIERRA:

### Path 1 — Operator Access
```
KEN, SPECTRO, mamba
        ↓
    VPN Server  (WireGuard — mutual cert auth)
        ↓
    SIERRA (full operator access via MAMBA)
```

### Path 2 — Demo Access
```
Demo participants / prospective customers
        ↓
    VPN Server  (separate instance, limited scope)
        ↓
    DemoGateway  (controlled zone inside SIERRA — read-only gallery, no control plane)
```

---

## Scope — What This Includes

- [ ] **VPN Server** setup on TAHOE rig or dedicated node (WireGuard)
- [ ] Operator certificate issuance for KEN, SPECTRO, mamba
- [ ] **DemoGateway** service inside SIERRA — dedicated nginx vhost, auth-only gallery
- [ ] Separate VPN profile for demo participants (limited scope, time-bounded)
- [ ] `make vpn-start`, `make vpn-add-operator`, `make vpn-add-demo` Makefile targets
- [ ] Update `make doctor` to check VPN server health
- [ ] Update architecture document (SIERRA-ARCHITECTURE.html) with new nodes

## What This Does NOT Include

- Full EDGE node certificate infrastructure (PR-005+)
- TAHOE-tier controller VPN (internal fabric only, separate from operator VPN)
- Production-grade PKI / CA automation (manual cert issuance for now)

---

## Architecture / Design Notes

- **SPECTRO** appears to be a new named operator or sensor system node — needs clarification
  (possibly a spectrum/RF sensor operator or a monitoring system)
- **DemoGateway** is inside SIERRA (pink boundary) — distinct from the SIERRA SIERRA
  customer gallery work done in PR #2. This is a VPN-authenticated gateway, not a hotspot
- Two separate VPN Server instances suggested in sketch — keeps operator and demo traffic isolated
- **DemoGateway** connects to MAMBA and the gallery infrastructure (read-only view of SIERRA assets)

---

## Implementation Plan

- [ ] WireGuard VPN server install and config (`infra/vpn/`)
- [ ] Operator peer config: KEN, SPECTRO, mamba
- [ ] DemoGateway nginx config: auth + limited scope
- [ ] Demo VPN peer config (separate, isolated subnet)
- [ ] Makefile targets: `make vpn-start`, `make add-operator`, `make add-demo-vpn`
- [ ] `make doctor` VPN checks
- [ ] Update SIERRA-ARCHITECTURE.html with new nodes (SPECTRO, DemoGateway, VPN Server)
- [ ] Update node registry table in SIERRA-CONTROL-CENTER.md

---

## Open Questions

1. **What is SPECTRO?** Spectrum analyzer / RF sensor system, or a new operator name?
2. **DemoGateway subnet** — what IP range for demo VPN clients?
3. **Cert lifetime** — how long should demo VPN certs be valid? (24h? per-session?)
4. **Single VPN server or two?** — sketch shows two separate VPN Server nodes; confirm intent
5. **KEN's role** — operator only, or does KEN also manage hardware at the VEGAS tier?

---

## Decisions Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-05-03 | VPN = WireGuard | Lightweight, fast, built into Linux kernel, easy config |
| 2026-05-03 | Two VPN paths (operator vs demo) | Isolate demo traffic from operator/control plane |
| 2026-05-03 | DemoGateway inside SIERRA | Demo participants get controlled view, not full access |

---

## Source Captures

| File | Content |
|------|---------|
| `capture/IMG_0215.jpeg` | Existing SIERRA/TAHOE/ALMANOR/DONNER architecture (context) |
| `capture/IMG_0216.jpeg` | PR #004 full whiteboard — VPN Server, DemoGateway, SPECTRO, KEN |
| `capture/IMG_0217.jpeg` | PR #004 — clearer view of same diagram |
| `capture/IMG_0218.jpeg` | PR #004 — closeup of KEN + SPECTRO → VPN Server path |
| `capture/IMG_0219.jpeg` | PR #004 — closeup of DemoGateway + Demo VPN path |
| `capture/IMG_0220.jpeg` | PR #004 — wide view showing SIERRA boundary + full access paths |
