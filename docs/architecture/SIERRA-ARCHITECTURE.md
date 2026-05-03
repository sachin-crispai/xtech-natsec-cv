# SIERRA Control Center — Architecture

---

## Page 1 — System Diagram

```mermaid
graph TD

  classDef vegasBrain fill:#4c1d95,stroke:#a855f7,stroke-width:3px,color:#f3e8ff
  classDef vegasOp    fill:#1e1b4b,stroke:#818cf8,stroke-width:2px,color:#c7d2fe
  classDef sierraHub  fill:#0c2340,stroke:#38bdf8,stroke-width:3px,color:#e0f2fe
  classDef subCtrl    fill:#052e16,stroke:#4ade80,stroke-width:2px,color:#dcfce7
  classDef edgeStd    fill:#431407,stroke:#f97316,stroke-width:2px,color:#ffedd5
  classDef edgeLite   fill:#292524,stroke:#fbbf24,stroke-width:1px,color:#fef9c3
  classDef edgeMin    fill:#1c1917,stroke:#9ca3af,stroke-width:1px,color:#f3f4f6
  classDef vpnNode    fill:#1e1b4b,stroke:#6366f1,stroke-width:1px,color:#e0e7ff

  subgraph VEGAS_TIER ["VEGAS TIER - Global Brain Centers  2-3 sites"]
    MEAD["MEAD<br>16x NVIDIA H200 SXM5<br>VRAM: 2.2 TB  BW: 76.8 TB/s<br>63 PFLOPS FP8<br>Foundation model training"]
    POWELL["POWELL<br>16x NVIDIA H200 SXM5<br>VRAM: 2.2 TB  BW: 76.8 TB/s<br>63 PFLOPS FP8<br>Training and inference"]
    HAVASU["HAVASU<br>8x NVIDIA H100 SXM5<br>VRAM: 640 GB  BW: 26.8 TB/s<br>32 PFLOPS FP8<br>Tertiary - future site"]
    MAMBA["mamba<br>RTX 3070 Ti  8 GB<br>Operator workstation<br>VPN-only  location-agnostic"]
  end

  subgraph SIERRA_ZONE ["SIERRA ZONE - Secure Operations  Las Vegas NV"]
    subgraph TAHOE_TIER ["TAHOE TIER - Operational Hubs  approx 200 nodes"]
      TAHOE["TAHOE  HUB<br>8x H100 SXM5<br>640 GB  32 PFLOPS<br>Central hub - all sync here"]
      SHASTA["SHASTA<br>8x H100 SXM5<br>640 GB  32 PFLOPS<br>Northern zone"]
      OROVILLE["OROVILLE<br>4x H100 SXM5<br>320 GB  16 PFLOPS<br>Central zone"]
      BERRYESSA["BERRYESSA<br>4x H100 SXM5<br>320 GB  16 PFLOPS<br>Southern zone"]
    end

    subgraph SUB_TIER ["SUB-CONTROLLERS - ALMANOR / DONNER Class  4-5 per hub"]
      ALMANOR["ALMANOR<br>2x L40S  96 GB<br>CV inference<br>Lake Almanor CA"]
      DONNER["DONNER<br>2x L40S  96 GB<br>CV inference<br>Donner Lake CA"]
      TENAYA["TENAYA<br>2x RTX 6000 Ada  96 GB<br>Edge aggregation<br>Tenaya Lake Yosemite"]
      CASCADE["CASCADE<br>2x RTX 6000 Ada  96 GB<br>Edge aggregation<br>Cascade Lake CA"]
      CONVICT["CONVICT<br>1x L40S  48 GB<br>Relay and inference<br>Convict Lake CA"]
    end
  end

  subgraph EDGE_TIER ["EDGE TIER - Drone Masters  approx 100000 nodes"]
    EDGE_STD["Standard Class<br>edge-00001 to edge-50000<br>1x RTX 4090  24 GB<br>Swarm control and inference<br>Failover to backup TAHOE hub"]
    EDGE_LITE["Lite Class<br>edge-50001 to edge-90000<br>1x RTX 3070  8 GB<br>Inference only<br>Failover to backup sub-ctrl"]
    EDGE_MIN["Minimal Class<br>edge-90001 to edge-99999<br>Jetson AGX Orin  32 GB<br>Ultra-light autonomous<br>Radio mesh or 5G"]
  end

  MEAD   <-->|VPN fabric NDR 400 GbE| TAHOE
  POWELL <-->|VPN fabric NDR 400 GbE| TAHOE
  HAVASU <-->|VPN fabric HDR 200 GbE| SHASTA
  MAMBA  -.->|VPN location-agnostic| TAHOE

  TAHOE    <-->|bidirectional sync| ALMANOR
  TAHOE    <-->|bidirectional sync| DONNER
  SHASTA   <-->|bidirectional sync| TENAYA
  SHASTA   <-->|bidirectional sync| CASCADE
  OROVILLE <-->|bidirectional sync| CONVICT

  ALMANOR  -->|controls assigned fleet| EDGE_STD
  DONNER   -->|controls assigned fleet| EDGE_STD
  TENAYA   -->|controls| EDGE_LITE
  CASCADE  -->|controls| EDGE_LITE
  CONVICT  -->|controls| EDGE_MIN

  class MEAD,POWELL,HAVASU vegasBrain
  class MAMBA              vegasOp
  class TAHOE,SHASTA,OROVILLE,BERRYESSA sierraHub
  class ALMANOR,DONNER,TENAYA,CASCADE,CONVICT subCtrl
  class EDGE_STD  edgeStd
  class EDGE_LITE edgeLite
  class EDGE_MIN  edgeMin
```

---

## Page 2 — Glossary, Tier Definitions & Commentary

### 4-Tier Hierarchy

```
VEGAS TIER            TOP — Global brain  H200 clusters  Foundation model training
  MEAD  POWELL  HAVASU     2-3 sites globally  63 PFLOPS each  2.2 TB VRAM
       |
       |  VPN fabric  WireGuard / IPSec  mutual cert auth
       |
SIERRA / TAHOE TIER — Operational control  ~200 H100 nodes  Mission execution
  TAHOE (hub)  SHASTA  OROVILLE  BERRYESSA  FOLSOM
       |
       |  internal fabric  InfiniBand HDR 200 Gb/s
       |
SUB-CONTROLLER TIER — Aggregation and CV inference  ~800-1000 nodes
  ALMANOR  DONNER  TENAYA  CASCADE  CONVICT  TOPAZ
       |
       |  assigned links  10-25 GbE  radio
       |
EDGE TIER             BOTTOM — Drone masters  approx 100000 nodes  Field inference
  edge-00001 to edge-99999   Standard / Lite / Minimal GPU classes
```

---

### Tier Definitions

#### VEGAS Tier — Global Brain Centers (2–3 sites)

The apex of the hierarchy. MEAD and POWELL are H200 super-clusters (16 cards each, 2.2 TB VRAM per site) that train the foundation models powering the entire fleet. Model weights flow downstream to TAHOE-tier controllers via the VPN fabric. mamba and other operator workstations also live in this tier but are not compute nodes — they are management interfaces that may be physically anywhere and always connect via VPN.

| Node | GPU Config | VRAM | FLOPS (FP8) | Role |
|------|-----------|------|-------------|------|
| **MEAD** | 16× H200 SXM5 | 2.2 TB | 63 PFLOPS | Primary brain — foundation training |
| **POWELL** | 16× H200 SXM5 | 2.2 TB | 63 PFLOPS | Secondary brain — training + inference |
| **HAVASU** | 8× H100 SXM5 | 640 GB | 32 PFLOPS | Tertiary / future site |
| **mamba** | 1× RTX 3070 Ti | 8 GB | — | Operator workstation · VPN-only |

#### TAHOE Tier — Operational Hubs inside SIERRA (approx 200 nodes)

The execution layer within the SIERRA secure zone. These nodes coordinate missions, run tactical inference, and manage the EDGE fleet. TAHOE is the central hub — all sub-controllers sync bidirectionally through it. Each hub manages a regional zone of the EDGE fleet.

| Node | GPU Config | VRAM | FLOPS | Zone |
|------|-----------|------|-------|------|
| **TAHOE ★** | 8× H100 SXM5 | 640 GB | 32 PFLOPS | Hub — all sync through here |
| **SHASTA** | 8× H100 SXM5 | 640 GB | 32 PFLOPS | Northern operational zone |
| **OROVILLE** | 4× H100 SXM5 | 320 GB | 16 PFLOPS | Central operational zone |
| **BERRYESSA** | 4× H100 SXM5 | 320 GB | 16 PFLOPS | Southern operational zone |
| **FOLSOM** | 4× H100 PCIe | 320 GB | 8 PFLOPS | Reserve / overflow |

#### Sub-Controller Tier — ALMANOR / DONNER Class (4–5 per hub, ~800–1,000 total)

Named after small Sierran alpine lakes. These nodes sit between TAHOE hubs and the raw EDGE fleet. They perform CV inference pre-processing, aggregate sensor data, and serve as the first failover target when an EDGE node loses its primary. GPU class is L40S or RTX 6000 Ada — CV-optimized, not training-capable.

| Node | GPU Config | VRAM | Role | Lake |
|------|-----------|------|------|------|
| **ALMANOR** | 2× L40S | 96 GB | CV inference | Lake Almanor, CA |
| **DONNER** | 2× L40S | 96 GB | CV inference | Donner Lake, CA |
| **TENAYA** | 2× RTX 6000 Ada | 96 GB | Edge aggregation | Tenaya Lake, Yosemite |
| **CASCADE** | 2× RTX 6000 Ada | 96 GB | Edge aggregation | Cascade Lake, CA |
| **CONVICT** | 1× L40S | 48 GB | Relay / inference | Convict Lake, CA |
| **TOPAZ** | 1× RTX 4090 | 24 GB | Minimal relay | Topaz Lake, CA/NV |

#### EDGE Tier — Drone Masters (~100,000 nodes)

The leaves of the hierarchy. Each EDGE drone master controls a local swarm, runs real-time inference, and reports status upstream. On loss of primary controller, it automatically fails over to its pre-assigned backup, syncs operational state, and continues the mission.

| Class | Range | GPU | VRAM | Failover target |
|-------|-------|-----|------|----------------|
| **Standard** | edge-00001 – 50000 | RTX 4090 | 24 GB GDDR6X | Backup TAHOE hub |
| **Lite** | edge-50001 – 90000 | RTX 3070 | 8 GB GDDR6 | Backup sub-ctrl |
| **Minimal** | edge-90001 – 99999 | Jetson AGX Orin | 32 GB unified | Backup sub-ctrl |

---

### Glossary

| Term | Definition |
|------|-----------|
| **SIERRA** | The physically and logically isolated secure zone in Las Vegas, NV. All operational compute lives inside SIERRA. Entry requires VPN authentication regardless of physical location. |
| **VPN fabric** | Encrypted tunnel linking VEGAS brain centers to SIERRA. Mutual certificate authentication. All cross-boundary traffic traverses this path. |
| **Failover** | Automatic promotion of backup controller when an EDGE node loses its primary. Includes state sync and mission continuation under backup custody. |
| **Custody transfer** | Hand-off of an EDGE node's swarm assignment between controllers. Triggered by failover or operator directive. |
| **NDR / HDR** | InfiniBand generations. NDR = 400 Gb/s (VEGAS clusters). HDR = 200 Gb/s (SIERRA clusters). |
| **NVLink 4** | NVIDIA GPU-to-GPU interconnect inside H200 nodes. Enables memory sharing across 16-card MEAD/POWELL configurations. |
| **PFLOPS FP8** | Peta floating-point ops/sec at FP8 precision — standard AI training throughput metric for H100/H200. |
| **mamba** | Operator workstation in the VEGAS tier. May be physically anywhere. Not a compute node. Always VPN — location-agnostic security posture. |
| **Naming convention** | All nodes named after California / western lakes. VEGAS tier uses large Nevada reservoirs (MEAD, POWELL, HAVASU). TAHOE tier uses large California lakes. Sub-controllers use small alpine Sierran lakes. |

---

*Source: docs/architecture/sierra-whiteboard-sketch.jpg · 810-26-NATSEC-CV · 2026-05-03*
