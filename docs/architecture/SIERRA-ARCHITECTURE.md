# SIERRA Control Center — Architecture
<!-- PAGE 1: DIAGRAM (landscape) -->
<div style="page-break-after: always"></div>

```mermaid
%%{init: {
  "theme": "base",
  "themeVariables": {
    "background": "#0d0d0f",
    "primaryColor": "#1a1a2e",
    "primaryTextColor": "#ffffff",
    "primaryBorderColor": "#444",
    "lineColor": "#888",
    "secondaryColor": "#16213e",
    "tertiaryColor": "#0f3460"
  }
}}%%

graph TD

  classDef vegasBrain  fill:#4A1579,stroke:#A855F7,stroke-width:3px,color:#fff,font-weight:bold
  classDef vegasOp     fill:#2D1B69,stroke:#7C3AED,stroke-width:2px,color:#ddd
  classDef sierraHub   fill:#0C3547,stroke:#0EA5E9,stroke-width:3px,color:#fff,font-weight:bold
  classDef subCtrl     fill:#064E3B,stroke:#10B981,stroke-width:2px,color:#fff
  classDef edgeStd     fill:#431407,stroke:#F97316,stroke-width:2px,color:#fff
  classDef edgeLite    fill:#3B1F0A,stroke:#FB923C,stroke-width:1px,color:#eee
  classDef edgeMin     fill:#1F2937,stroke:#6B7280,stroke-width:1px,color:#ccc
  classDef vpnConn     fill:#1e293b,stroke:#334155,stroke-width:1px,color:#94a3b8

  %% ── VEGAS TIER ──────────────────────────────────────────────────────────────
  subgraph VEGAS_ZONE["🧠  VEGAS TIER — Global Brain Centers  (2–3 sites)"]
    direction LR
    MEAD["**MEAD**
    ──────────────────
    16 × H200 SXM5
    VRAM  : 2.2 TB
    BW    : 76.8 TB/s
    FLOPS : 63 PFLOPS
    Role  : Foundation training
    Status: Primary brain"]

    POWELL["**POWELL**
    ──────────────────
    16 × H200 SXM5
    VRAM  : 2.2 TB
    BW    : 76.8 TB/s
    FLOPS : 63 PFLOPS
    Role  : Training + inference
    Status: Secondary brain"]

    HAVASU["**HAVASU**
    ──────────────────
    8 × H100 SXM5
    VRAM  : 640 GB
    BW    : 26.8 TB/s
    FLOPS : 32 PFLOPS
    Role  : Tertiary / future
    Status: Planned"]

    MAMBA["**mamba**
    ──────────────────
    1 × RTX 3070 Ti
    VRAM  : 8 GB
    Role  : Operator node
    Access: VPN-only
    Note  : Location-agnostic"]
  end

  %% ── SIERRA ZONE ─────────────────────────────────────────────────────────────
  subgraph SIERRA_ZONE["🔒  SIERRA ZONE — Secure Operations  (Las Vegas, NV)"]
    direction TB

    subgraph TAHOE_TIER["  TAHOE Tier — Operational Hubs  (~200 nodes total)  "]
      direction LR
      TAHOE["**TAHOE**  ★ hub
      ─────────────────
      8 × H100 SXM5
      VRAM  : 640 GB
      BW    : 26.8 TB/s
      FLOPS : 32 PFLOPS
      Role  : Central hub
      All sub-ctrl sync here"]

      SHASTA["**SHASTA**
      ─────────────────
      8 × H100 SXM5
      VRAM  : 640 GB
      BW    : 26.8 TB/s
      FLOPS : 32 PFLOPS
      Role  : North zone"]

      OROVILLE["**OROVILLE**
      ─────────────────
      4 × H100 SXM5
      VRAM  : 320 GB
      BW    : 13.4 TB/s
      FLOPS : 16 PFLOPS
      Role  : Central zone"]

      BERRYESSA["**BERRYESSA**
      ─────────────────
      4 × H100 SXM5
      VRAM  : 320 GB
      BW    : 13.4 TB/s
      FLOPS : 16 PFLOPS
      Role  : South zone"]
    end

    subgraph SUB_TIER["  Sub-Controllers — ALMANOR / DONNER Class  (4–5 per hub)  "]
      direction LR
      ALMANOR["**ALMANOR**
      ─────────────
      2 × L40S
      VRAM: 96 GB
      CV inference"]

      DONNER["**DONNER**
      ─────────────
      2 × L40S
      VRAM: 96 GB
      CV inference"]

      TENAYA["**TENAYA**
      ─────────────
      2 × RTX 6000 Ada
      VRAM: 96 GB
      Edge aggregation"]

      CASCADE["**CASCADE**
      ─────────────
      2 × RTX 6000 Ada
      VRAM: 96 GB
      Edge aggregation"]

      CONVICT["**CONVICT**
      ─────────────
      1 × L40S
      VRAM: 48 GB
      Relay / inference"]
    end
  end

  %% ── EDGE TIER ───────────────────────────────────────────────────────────────
  subgraph EDGE_ZONE["⚡  EDGE TIER — Drone Masters  (~100,000 nodes)"]
    direction LR
    EDGE_STD["**Standard Class**
    edge-00001 … edge-50000
    ─────────────────────
    1 × RTX 4090  |  24 GB
    Swarm control + inference
    Primary: assigned TAHOE hub
    Failover: backup hub"]

    EDGE_LITE["**Lite Class**
    edge-50001 … edge-90000
    ─────────────────────
    1 × RTX 3070  |  8 GB
    Inference only
    Primary: assigned sub-ctrl
    Failover: backup sub-ctrl"]

    EDGE_MIN["**Minimal Class**
    edge-90001 … edge-99999
    ─────────────────────
    Jetson AGX Orin  |  32 GB
    Ultra-light deployments
    Radio mesh / 5G
    Autonomous capable"]
  end

  %% ── CONNECTIONS ─────────────────────────────────────────────────────────────
  MEAD    <-->|"VPN fabric\nNDR 400 GbE\nModel sync"| TAHOE
  POWELL  <-->|"VPN fabric\nNDR 400 GbE\nModel sync"| TAHOE
  HAVASU  <-->|"VPN fabric\nHDR 200 GbE"| SHASTA
  MAMBA   -. "VPN\n(location agnostic)" .-> TAHOE

  TAHOE     <-->|"bidirectional\nsync"| ALMANOR
  TAHOE     <-->|"bidirectional\nsync"| DONNER
  SHASTA    <-->|"bidirectional\nsync"| TENAYA
  SHASTA    <-->|"bidirectional\nsync"| CASCADE
  OROVILLE  <-->|"bidirectional\nsync"| CONVICT

  ALMANOR -->|"control\nassigned fleet"| EDGE_STD
  DONNER  -->|"control\nassigned fleet"| EDGE_STD
  TENAYA  -->|"control"| EDGE_LITE
  CASCADE -->|"control"| EDGE_LITE
  CONVICT -->|"control"| EDGE_MIN

  %% ── STYLE ASSIGNMENTS ───────────────────────────────────────────────────────
  class MEAD,POWELL,HAVASU     vegasBrain
  class MAMBA                  vegasOp
  class TAHOE,SHASTA,OROVILLE,BERRYESSA  sierraHub
  class ALMANOR,DONNER,TENAYA,CASCADE,CONVICT  subCtrl
  class EDGE_STD               edgeStd
  class EDGE_LITE              edgeLite
  class EDGE_MIN               edgeMin
```

---
<!-- PAGE 2: GLOSSARY + HIERARCHY COMMENTARY -->
<div style="page-break-before: always"></div>

## Page 2 — Glossary, Tier Definitions & Commentary

---

### Terminology

| Term | Definition |
|------|-----------|
| **SIERRA** | The secure control zone — a physically and logically isolated environment in Las Vegas, NV. All operational compute lives inside SIERRA. Entry requires VPN authentication. |
| **TAHOE tier** | The hub-level operational controllers inside SIERRA. Named after large California lakes. ~200 nodes, H100 class. The hub node (TAHOE) is the central sync point — all sub-controllers report through it. |
| **Sub-controller** (ALMANOR/DONNER class) | Intermediate layer between TAHOE hubs and EDGE nodes. Named after small California alpine lakes. Handles data aggregation, CV inference pre-processing, and act as the buffer layer between the core and the edge fleet. |
| **EDGE tier** | ~100,000 drone master nodes deployed at field periphery. Limited GPU (inference only). Operate semi-autonomously. Each EDGE node is assigned a primary and a backup controller. On loss of primary connectivity, it fails over automatically. |
| **VEGAS tier** | The global brain — 2–3 geographically distributed centers outside SIERRA but securely linked via VPN. Contains the highest-density compute (H100/H200 clusters). Responsible for foundation model training and fleet-wide intelligence. **These are the top of the hierarchy.** |
| **mamba** | An operator workstation that lives in the VEGAS tier. It may be physically anywhere — inside a VEGAS center, in a hotel, or in the field. Its security posture does not change: always VPN, always authenticated. mamba is not itself a compute brain. |
| **VPN fabric** | The encrypted tunnel linking VEGAS brain centers to SIERRA. Uses mutual certificate authentication. All cross-boundary traffic traverses this path. |
| **Failover** | When an EDGE node loses its primary controller, it autonomously promotes its backup controller, syncs operational state, and continues the mission under backup custody. |
| **Custody transfer** | The hand-off of an EDGE node's swarm assignment between controllers. Triggered by failover or by operator directive when the primary recovers. |
| **NDR / HDR** | InfiniBand generations. NDR (Next Data Rate) = 400 Gb/s. HDR (High Data Rate) = 200 Gb/s. Used for high-speed GPU cluster interconnect inside VEGAS and SIERRA respectively. |
| **NVLink 4** | NVIDIA's high-bandwidth GPU interconnect inside H200 nodes. Used within VEGAS brain centers to allow GPU-to-GPU memory sharing across the full node. |
| **PFLOPS FP8** | Peta floating-point operations per second at FP8 precision — the standard metric for AI training throughput on H100/H200 hardware. |

---

### Node Naming Convention

All named compute nodes follow the **California lakes convention** — except VEGAS-tier sites which use large western reservoirs near Nevada (MEAD, POWELL, HAVASU) to reflect their geographic context.

| Sub-category | Examples | Lake character |
|-------------|---------|---------------|
| VEGAS Brain | MEAD, POWELL, HAVASU | Largest western reservoirs — matching top-tier scale |
| TAHOE Hubs | TAHOE, SHASTA, OROVILLE, BERRYESSA, FOLSOM | Large California reservoirs |
| Sub-controllers | ALMANOR, DONNER, TENAYA, CASCADE, CONVICT, TOPAZ | Small alpine lakes — Sierran character |
| EDGE nodes | edge-00001 … edge-99999 | Sequential — too large for lake names |

---

### 4-Tier Hierarchy

```
VEGAS Tier          ← TOP — global brain, foundation model training
      ↕ VPN
SIERRA / TAHOE Tier ← operational control, ~200 H100 nodes, mission execution
      ↓ fabric
Sub-controller Tier ← aggregation, CV inference, EDGE buffer
      ↓ assigned
EDGE Tier           ← BOTTOM — ~100,000 drone masters, field inference
```

**VEGAS (Brain — 2–3 sites)**
The apex of the hierarchy. MEAD and POWELL are H200 super-clusters (16 cards each, 2.2 TB VRAM per site) responsible for training the foundation models that power the entire fleet. They send trained model weights down to TAHOE-tier controllers via the VPN fabric. mamba and other operator workstations also live in this tier but are not compute nodes — they are management interfaces.

**TAHOE Tier (Operational — ~200 nodes)**
The execution layer within SIERRA. These nodes coordinate missions, run tactical inference, and manage the EDGE fleet. TAHOE is the hub — all four sub-controllers (ALMANOR, DONNER, TENAYA, CASCADE) sync bidirectionally through it. The unlabeled ovals in the whiteboard sketch represent the GPU compute pods hanging off each hub. Each hub manages a regional zone of the EDGE fleet.

**Sub-Controller Tier (Aggregation — ~800–1,000 nodes)**
Named after small Sierran lakes. These nodes sit between the TAHOE hubs and the raw EDGE fleet. They perform CV inference pre-processing (reducing what needs to be sent upstream), aggregate sensor data, and serve as the first failover target when an EDGE node loses its primary. GPU class is L40S or RTX 6000 Ada — CV-optimized, not training-capable.

**EDGE Tier (Field — ~100,000 nodes)**
The leaves of the hierarchy. Each EDGE drone master controls a local swarm, runs real-time inference (YOLO-class models, sensor fusion), and reports status upstream. Three hardware classes exist: Standard (RTX 4090), Lite (RTX 3070), and Minimal (Jetson AGX Orin). All three classes implement the same failover protocol: heartbeat → retry → promote backup → sync state → continue.

---

### Open Questions for Next Sprint

1. **Failover protocol spec** — heartbeat interval, retry count, state payload definition
2. **VPN topology** — hub-and-spoke (TAHOE as hub) vs. full mesh between VEGAS + SIERRA
3. **Model distribution pipeline** — how trained weights flow from MEAD/POWELL down to EDGE nodes
4. **Cert authority** — issuing and rotating ~100,000 EDGE mutual-auth certs at scale
5. **EDGE autonomous floor** — minimum capability when fully disconnected from SIERRA

---

*Source: whiteboard sketch 2026-05-03 · `docs/architecture/sierra-whiteboard-sketch.jpg`*
