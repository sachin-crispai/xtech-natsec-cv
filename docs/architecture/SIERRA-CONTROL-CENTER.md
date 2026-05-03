# SIERRA Control Center — Architecture

**Source sketch:** `docs/architecture/sierra-whiteboard-sketch.jpg`  
**Date:** 2026-05-03  
**Status:** Requirements capture — work in progress

---

## 1. Executive Summary

SIERRA is a secure, geographically anchored control center located in **Las Vegas, NV**.
It is the nerve center for a large-scale distributed compute and drone operations network.

Key characteristics:
- **Secure boundary** — SIERRA is a VPN-isolated zone; all access is authenticated
- **Hybrid presence** — operators (e.g. mamba) may be physically inside or anywhere in Vegas / the field, connecting via VPN
- **Tiered compute** — a small number of high-power training controllers (TAHOE tier) at the core, a massive edge fleet at the periphery
- **Resilient edge** — EDGE controllers are designed to operate autonomously and failover to backup controllers if their primary is unreachable

---

## 2. Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│  SIERRA  (secure control zone — Las Vegas, NV)                  │
│                                                                  │
│   ┌──────────┐        ┌──────────────────────────────────┐      │
│   │ ALMANOR  │◄──────►│                                  │      │
│   └──────────┘        │          TAHOE (hub)             │      │
│                       │    H100/H200 · training-capable  │      │
│   ┌──────────┐        │                                  │      │
│   │ DONNER   │◄──────►│                                  │      │
│   └──────────┘        └──────────────────────────────────┘      │
│        ·  ·  ·  (CRATER, SHASTA, MONO …)                        │
│                                                                  │
└──────────────┬───────────────────────────────────────────────────┘
               │ VPN (encrypted tunnel)
               │
        ┌──────┴──────────────────────────┐
        │  VEGAS  (field / remote zone)   │
        │                                  │
        │   ┌─────────────────────────┐   │
        │   │  mamba  (laptop / node) │   │
        │   │  · may be in Vegas      │   │
        │   │  · may be in the field  │   │
        │   │  · connects via VPN     │   │
        │   └─────────────────────────┘   │
        └──────────────────────────────────┘

                      ▼  ▼  ▼
        ┌─────────────────────────────────────────────────┐
        │  EDGE  (drone master periphery)                 │
        │                                                  │
        │   drone-001  drone-002  ···  drone-100000        │
        │   · limited GPU (inference / lightweight ops)   │
        │   · connects to assigned SIERRA controller      │
        │   · failover to backup controller if primary    │
        │     is unreachable                              │
        └─────────────────────────────────────────────────┘
```

---

## 3. Node Taxonomy

### 3.1 SIERRA Core Controllers (TAHOE Tier)

| Property | Value |
|----------|-------|
| Location | Inside SIERRA secure zone, Las Vegas |
| Count | ~200 nodes |
| GPU class | NVIDIA H100 / H200 (datacenter grade) |
| VRAM | 80–141 GB per card, multiple cards per node |
| Role | Large-scale model training, inference, mission coordination |
| Connectivity | Direct fabric (NVLink / InfiniBand within cluster) + VPN ingress |
| Named nodes (confirmed) | TAHOE (hub), ALMANOR, DONNER |
| Named nodes (planned) | CRATER, SHASTA, MONO, FALLEN LEAF, EMERALD BAY … |
| Naming convention | California lakes |

**TAHOE** is the central hub — other controllers sync through it. ALMANOR and DONNER are sub-controllers with bidirectional sync to TAHOE (visible in sketch).

### 3.2 VPN / Remote Nodes (VEGAS Tier)

| Property | Value |
|----------|-------|
| Example node | mamba (MacBook Pro, Intel, current dev machine) |
| Location | Anywhere — inside Vegas center, field deployment, hotel, etc. |
| Connectivity | VPN into SIERRA |
| Role | Operator workstation, mission monitoring, dev/test, gallery/demo |
| GPU | Workstation-class (RTX 3070 Ti, etc.) |
| Notes | mamba is the current NATSEC-CV dev node. May be physically co-located with SIERRA or remote — always VPN-secured. |

### 3.3 EDGE Drone Masters (EDGE Tier)

| Property | Value |
|----------|-------|
| Count | ~100,000 nodes |
| Location | Field periphery — deployed with drone swarms |
| GPU class | Limited (inference only — RTX 3070 class or lighter) |
| Role | Drone master controller — manages local drone swarm, runs inference, reports to SIERRA controller |
| Primary link | Assigned SIERRA controller (TAHOE tier) |
| Failover | On loss of primary, EDGE node attempts connection with designated backup controller and syncs operational state |
| Autonomy | Must be capable of limited autonomous operation during connectivity gaps |

---

## 4. Security Zones

```
Zone          Boundary         Access method          Trust level
──────────────────────────────────────────────────────────────────
SIERRA Core   Physical + VPN   Internal fabric only   Full trust
VEGAS/Remote  VPN only         Authenticated VPN      Operator trust
EDGE          Radio/Internet   Encrypted + mutual auth  Limited trust
Public        None             No access              Zero trust
```

- **SIERRA** is the secure perimeter. No inbound traffic without VPN authentication.
- **mamba** and other VEGAS-tier nodes always enter via VPN regardless of physical location.
- **EDGE** nodes use mutual authentication to prevent rogue controllers from hijacking swarms.

---

## 5. Failover Behavior (EDGE Tier)

When an EDGE drone master loses contact with its primary SIERRA controller:

```
1. EDGE detects heartbeat timeout (threshold TBD)
2. EDGE attempts reconnect to primary (N retries, backoff TBD)
3. If primary unreachable → EDGE promotes to BACKUP controller
4. EDGE syncs operational state with backup controller
5. Backup controller assumes custody of the EDGE node's swarm
6. Primary comes back online → custody transfer back (or operator-directed)
```

Requirements to define:
- Heartbeat interval and timeout threshold
- Number of retry attempts before failover
- Backup controller assignment strategy (static list vs. discovery)
- State sync protocol between EDGE node and backup
- Custody transfer handshake when primary recovers

---

## 6. Named Nodes (Current + Planned)

All node names follow the **California lakes** convention.

| Node | Tier | Status | Notes |
|------|------|--------|-------|
| TAHOE | SIERRA Core (hub) | Active | Central hub controller, H100/H200 cluster |
| ALMANOR | SIERRA Core | Planned | Sub-controller, syncs with TAHOE |
| DONNER | SIERRA Core | Planned | Sub-controller, syncs with TAHOE |
| CRATER | SIERRA Core | Proposed | Future controller |
| SHASTA | SIERRA Core | Proposed | Future controller |
| MONO | SIERRA Core | Proposed | Future controller |
| mamba | VEGAS / Remote | Active | Dev/operator node, VPN access |
| SIERRA | Zone name | — | Not a node — the secure zone boundary |
| EDGE-xxxxx | EDGE | ~100,000 | Drone master nodes, sequentially named |

---

## 7. Open Requirements

The following must be designed and implemented to complete the secure center:

### Network & VPN
- [ ] VPN server within SIERRA (WireGuard / OpenVPN / IPSec — TBD)
- [ ] Certificate authority for mutual authentication (EDGE ↔ SIERRA)
- [ ] Network segmentation: SIERRA fabric vs. VPN ingress vs. EDGE link
- [ ] Static IP / DNS for all TAHOE-tier nodes within SIERRA

### Controller Software (TAHOE Tier)
- [ ] Controller registration and discovery service
- [ ] EDGE node onboarding and assignment to primary controller
- [ ] Backup controller assignment table
- [ ] Heartbeat monitoring and failover trigger
- [ ] Operational state sync protocol

### EDGE Tier
- [ ] Failover client: heartbeat, retry, backup promotion
- [ ] State sync: what operational state is synced on failover
- [ ] Minimal autonomous operation capability during connectivity gap
- [ ] Secure boot / attestation for EDGE hardware

### mamba / VEGAS Tier
- [ ] VPN client configuration and auto-connect
- [ ] Role-based access control (what can remote operators do vs. in-SIERRA operators)
- [ ] Gallery / demo access (SIERRA-authenticated, already started in PR #2)

### Infrastructure
- [ ] Hardware procurement plan: H100/H200 nodes for TAHOE tier
- [ ] Physical rack layout within SIERRA center (see `platform/gpu/` inventory)
- [ ] Power + cooling budget for ~200 H100/H200 nodes
- [ ] Network fabric: InfiniBand vs. RoCE vs. Ethernet for TAHOE cluster

---

## 8. Diagram Reference

Original whiteboard sketch captured 2026-05-03:

![SIERRA whiteboard sketch](sierra-whiteboard-sketch.jpg)

Key elements visible:
- **Pink boundary** = SIERRA secure zone
- **TAHOE** (green oval, center) = hub controller with bidirectional links to ALMANOR and DONNER
- **Unnamed green ovals** = GPU compute nodes attached to each controller
- **VEGAS / MAMBA** (purple, outside boundary) = remote/field node connected via VPN (dashed line)
- **SIERRA label** (pink arrow) = zone boundary annotation

---

## 9. Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-05-03 | Node naming: California lakes | Geographically rooted, memorable, no vendor lock-in |
| 2026-05-03 | TAHOE = hub controller | Established as primary node in existing work |
| 2026-05-03 | EDGE count target: ~100,000 | Per mission scale requirements |
| 2026-05-03 | SIERRA core count target: ~200 | H100/H200 class, training-capable |
| 2026-05-03 | mamba = VPN-only access | Physical location variable; VPN ensures consistent security posture |
