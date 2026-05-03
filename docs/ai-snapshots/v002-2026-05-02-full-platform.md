# Project Snapshot: CRISP AI — SensorFuse + GPU Platform
**Version:** v002  
**Date:** 2026-05-02  
**Author:** Sachin Naik, CRISP AI  
**Intended consumers:** Claude Desktop, ChatGPT, Gemini, human technical reviewers  
**Snapshot purpose:** Master context document covering both the SensorFuse software system and the CRISP AI GPU hardware platform — suitable for cold-paste into any AI session.

---

## 1. Executive Summary

CRISP AI is competing in the **Army FUZE xTech National Security Hackathon** (May 2–3, 2026, SHACK 15, San Francisco) under **Capability 1: Sensor Analysis and Integration**.

The project is called **SensorFuse** — a real-time multi-sensor fusion pipeline that correlates EO, IR, and RF detections into a single confidence-scored operational picture with persistent target custody and evasion detection.

Two parallel workstreams are active:

1. **Software (SensorFuse)** — FastAPI backend + React tactical dashboard, functional at demo-prototype quality
2. **Hardware Platform** — CRISP AI GPU rig inventory (18 GPUs across 3 open-air chassis), physically surveyed and documented

**Prize pool:** $50K total, top prize $20K.  
**GitHub:** https://github.com/sachin-crispai/xtech-natsec-cv

---

## 2. Hackathon Evaluation Criteria

| Criterion | Weight | Our Approach |
|-----------|--------|-------------|
| Technical Demo | 35% | Live sensor feed → fusion → map, all real-time via WebSocket |
| Military Impact | 30% | Solves custody loss in contested environments (EO/IR/RF gap) |
| Solution Creativity | 25% | Cross-modal evasion-pattern detection |
| Pitch | 10% | NL query interface for non-technical operators |

---

## 3. Repository Structure

```
.
├── README.md                         # Project overview and quick start
├── backend/                          # FastAPI backend
│   ├── api/
│   │   ├── main.py                   # App setup, startup tasks, WebSocket broadcasting
│   │   └── routers/                  # Sensors, tracks, alerts REST endpoints
│   ├── core/
│   │   ├── event_bus.py              # In-process async event bus
│   │   └── models.py                 # Pydantic: Detection, Track, Alert
│   ├── fusion/
│   │   └── tracker.py                # Track association + Kalman-style smoothing + evasion scoring
│   ├── sensors/
│   │   └── simulator.py              # Simulated EO/IR/RF moving target detections
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/                         # React/Vite tactical dashboard
│   ├── src/
│   │   ├── App.tsx                   # Main layout
│   │   ├── components/               # TacticalMap, TrackPanel, AlertFeed, StatusBar
│   │   ├── hooks/useWebSocket.ts     # Live track stream client
│   │   ├── store/useTrackStore.ts    # Client-side state (Zustand)
│   │   └── types.ts
│   └── Dockerfile
├── platform/gpu/                     # Hardware inventory
│   ├── inventory/                    # Full survey: HARDWARE_INVENTORY.md + IMG_0074–0083
│   └── approved/                     # Chain-of-custody survey: APPROVED_INVENTORY.md + IMG_0089–0093
├── rfi/                              # xTech RFI PDF
└── docs/ai-snapshots/                # This directory — versioned AI/PM context snapshots
```

---

## 4. SensorFuse — Software State

### 4.1 What Is Implemented

**Backend (FastAPI)**
- Startup tasks: simulator, tracker, and WebSocket broadcast loop all launch on app start
- `/health` — service status + active track count
- `/ws/tracks` — live WebSocket stream of fused track state
- `/api/sensors/`, `/api/tracks/`, `/api/alerts/` — REST routers (see gaps below)
- Pydantic models: `Detection`, `Track`, `Alert`
- Simulated targets: randomized EO/IR/RF detections over a shared geographic area
- Track association: nearest-neighbor by geographic proximity with configurable distance threshold
- Kalman-style smoothing: weighted moving average of position and velocity across observations
- Evasion scoring: dropout ratio over a sliding time window; tracks exceeding 60% dropout threshold are flagged
- Alert publication: new track, multi-sensor confirmation, evasion candidate events

**Frontend (React + Vite + TypeScript)**
- `StatusBar` — connection state, track count, sensor health
- `TrackPanel` — live list of active tracks with confidence and modality indicators
- `TacticalMap` — Leaflet-based map rendering track positions
- `AlertFeed` — real-time alert log
- WebSocket hook consuming `/ws/tracks`
- Zustand store for client-side track/sensor state

### 4.2 Known Gaps (Demo Blockers First)

| Priority | Gap | Impact |
|----------|-----|--------|
| High | `tracker.py` updates an internal store but does NOT call `tracks.update_store` — `/api/tracks/` likely returns stale or empty data | REST endpoint broken for tracks |
| High | Alerts are published on the event bus but NOT wired into `alerts.push_alert` — `/api/alerts/` likely empty | REST endpoint broken for alerts |
| Medium | Frontend uses hardcoded `http://localhost:8000` — breaks outside dev environment | Demo fragility |
| Medium | README mentions YOLOv8 video detection, Redis persistence, and NL query — none confirmed in current code | Credibility risk with judges |
| Low | `@app.on_event("startup")` is deprecated in modern FastAPI; lifespan handlers preferred | Clean-up, not blocking |
| Low | No tests for tracker association, alert publication, or event bus behavior | Tech debt |

### 4.3 Demo Narrative (How to Present It)

1. Simulated EO, IR, and RF sensors generate detections over a shared area of operations
2. The event bus routes detections to the fusion tracker
3. Tracker associates detections into persistent tracks with confidence scoring
4. Tracks stream live to the dashboard over WebSocket
5. Operator sees: track map, confidence, sensor modality badges, evasion alert flags

**Honest framing:** This is a simulation-driven prototype. Real sensor adapters, video detection, and persistence are next-stage. The fusion + evasion detection logic is the technical core being demonstrated.

### 4.4 Near-Term Software Priorities

1. Wire tracker output into `/api/tracks/` so REST and WebSocket are consistent
2. Wire alerts into `/api/alerts/` so the frontend alert feed shows real data
3. Make backend URL environment-configurable in the frontend
4. Update README to separate "implemented," "simulated," and "planned"
5. Add a demo script (expected observations + fallback screenshots)
6. Add minimal backend tests for association + alert publication

### 4.5 Software Roadmap (Post-Hackathon)

- Replace simulated EO with real video-frame YOLO detections
- Add real or recorded IR/RF sensor adapters
- Persist tracks and alerts in Redis
- Implement track history playback and export
- Add NL query interface once track state is reliable
- Add authentication, deployment config, and observability
- Research: compare JPDA, MHT, factor graph, and learned association approaches

---

## 5. GPU Hardware Platform — Inventory

### 5.1 Survey Context

- **Survey dates:** 2026-05-01
- **Surveyors:** Ken Choi, Sachin Naik
- **Location:** CRISP AI office (San Francisco)
- **Chain-of-custody method:** Approved images contain a sandal in frame as physical presence marker
- **Source images:** `platform/gpu/inventory/` (IMG_0074–0083) and `platform/gpu/approved/` (IMG_0089–0093)

### 5.2 Confirmed GPU Inventory (Approved Images)

**3 open-air steel mining chassis, 6 slots each = 18 GPU slots total**

#### Chassis 1 — XFX / MSI / Mixed

| Slot | Brand | Model | VRAM | Confidence |
|------|-------|-------|------|------------|
| 1 | XFX | GeForce RTX (model TBD) | 8 GB est. | Medium |
| 2 | XFX | GeForce RTX (model TBD) | 8 GB est. | Medium |
| 3 | MSI | GeForce RTX (model TBD) | 8 GB est. | High brand, low model |
| 4–6 | Unknown | GeForce RTX (model TBD) | 8 GB est. | Low |

#### Chassis 2 — EVGA RTX 3070 / MSI Mixed

| Slot | Brand | Model | VRAM | Confidence |
|------|-------|-------|------|------------|
| 1 | EVGA | RTX 3070 | 8 GB GDDR6 | **High** |
| 2 | EVGA | RTX 3070 | 8 GB GDDR6 | **High** |
| 3 | MSI | GeForce RTX (model TBD) | 8 GB est. | High brand |
| 4 | MSI | GeForce RTX (model TBD) | 8 GB est. | High brand |
| 5–6 | Unknown | GeForce RTX | 8 GB est. | Medium |

#### Chassis 3 — EVGA RTX 3070 / 3070 Ti

| Slot | Brand | Model | VRAM | Confidence |
|------|-------|-------|------|------------|
| 1 | EVGA | RTX 3070 | 8 GB GDDR6 | **High** |
| 2 | EVGA | RTX 3070 | 8 GB GDDR6 | **High** |
| 3 | EVGA | RTX 3070 or 3070 Ti | 8 GB | Medium (angle-obscured) |
| 4 | EVGA | RTX 3070 Ti | 8 GB GDDR6X | **High** |
| 5 | EVGA | RTX 3070 Ti | 8 GB GDDR6X | **High** |
| 6 | EVGA | RTX 3070 Ti | 8 GB GDDR6X | **High** |

### 5.3 Consolidated GPU Summary

| GPU | Brand | Qty | VRAM | Confidence |
|-----|-------|-----|------|------------|
| RTX 3070 | EVGA | 4 confirmed | 8 GB GDDR6 | High |
| RTX 3070 Ti | EVGA | 3 confirmed | 8 GB GDDR6X | High |
| RTX (model TBD) | EVGA | 1 | 8 GB est. | Medium |
| RTX (model TBD) | MSI | 3 | 8 GB est. | High brand, low model |
| RTX (model TBD) | XFX | 2 | 8 GB est. | Medium brand |
| RTX (model TBD) | Unknown | 5 | 8 GB est. | Low |
| **Total** | | **18** | **~144 GB** | |

### 5.4 Non-GPU Hardware

- ATX PSU: standalone unit visible beside Chassis 3 (brand/wattage unconfirmed)
- Open-air mining frames: 3 confirmed (steel, 6-slot each)
- Aluminum flight case: present in scene, contents unknown
- PCIe riser extenders (x1-to-x16) throughout
- Wiring: blue and yellow molex/PCIe cables

### 5.5 Hackathon Build — 2-Rack Configuration (From Existing Inventory)

#### Rack A — Primary (training + heavy inference)

| Slot | GPU | VRAM | Power |
|------|-----|------|-------|
| 1–6 | EVGA RTX 3070 Ti × 6 | 8 GB each / **48 GB total** | ~290 W each / **~1,740 W** |

#### Rack B — Secondary (inference + parallel experiments)

| Slot | GPU | VRAM | Power |
|------|-----|------|-------|
| 1 | EVGA RTX 3070 Ti | 8 GB | ~290 W |
| 2–5 | EVGA RTX 3070 × 4 | 8 GB each | ~220 W each |
| 6 | MSI RTX 30-series | 8 GB est. | ~220–290 W |
| **Total** | | **48 GB** | **~1,430–1,530 W** |

**Combined two-rack: 12 GPUs / 96 GB VRAM / ~3,240 W GPU power / $0 incremental cost (owned)**

### 5.6 Workloads Supported at Hackathon Scale (8 GB/card)

| Workload | Notes |
|----------|-------|
| YOLOv8/v9 | Full training + inference |
| ResNet-50/101, EfficientDet | Fine-tuning + inference |
| Detectron2 | Training at batch 2–4/GPU |
| ViT-S / ViT-B | Inference and fine-tuning |
| CLIP, DINOv2 (ViT-B) | Zero-shot CV pipelines |
| Stable Diffusion 1.5/2.1 | Synthetic data / augmentation |
| PyTorch DDP | Distributed across all 12 GPUs |
| Whisper (medium/large-v2) | Audio transcription |

> Models > 8B params and SAM-H / ViT-H / SDXL require quantization at this VRAM tier.

### 5.7 Proposed Future Platform Upgrade

For production NATSEC CV workloads (post-hackathon):

| Rack | GPU | VRAM | BW | TDP | Est. Cost |
|------|-----|------|----|-----|-----------|
| Training | 6× NVIDIA L40S | 48 GB each / 288 GB | 864 GB/s | 300 W | ~$60–90K |
| Inference | 6× NVIDIA RTX 6000 Ada | 48 GB each / 288 GB | 864 GB/s | 300 W | ~$36–48K |
| **Combined** | | **576 GB** | | **~3,600 W** | **~$96–138K** |

Upgrade path: swap L40S slots for H100 PCIe (same form factor, 350 W, 80 GB HBM2e each) for 480 GB HBM aggregate.

### 5.8 Hardware Open Items

- [ ] Photograph IO bracket or PCB sticker on each unidentified card for model/serial
- [ ] Confirm XFX model (likely RTX 3070 or 3080)
- [ ] Confirm MSI model (same bracket approach)
- [ ] Confirm 5 unbranded RTX cards (silver shroud suggests ASUS, Gigabyte, or Zotac)
- [ ] Confirm Chassis 3 Slot 3 (3070 or 3070 Ti — angle obscured)
- [ ] Inspect standalone PSU model + wattage
- [ ] Document aluminum flight case contents
- [ ] Review `platform/gpu/inventory/IMG_0072.MOV` (video not yet assessed)
- [ ] Record serial numbers and asset tags per GPU

---

## 6. Decisions Log

| Date | Decision | Rationale | Status |
|------|----------|-----------|--------|
| 2026-05-01 | Use sandal-in-frame as chain-of-custody marker for GPU photos | Lightweight physical presence verification without specialized equipment | Accepted |
| 2026-05-02 | Hackathon build uses 2 racks from existing inventory (12 of 18 GPUs) | Zero incremental cost; Rack A is all-identical 3070 Ti for cleanest config | Accepted |
| 2026-05-02 | Simulation-driven demo is acceptable baseline for hackathon | Real sensor adapters require hardware not available in 24h; simulation demonstrates the fusion logic clearly | Accepted |
| 2026-05-02 | Store AI context snapshots in `docs/ai-snapshots/` versioned with the repo | Keeps requirements and AI responses in the same git history as the code | Accepted |
| 2026-05-02 | Proposed upgrade racks: L40S (training) + RTX 6000 Ada (inference) | Best VRAM/cost balance for on-prem air-gappable NATSEC CV workloads at PCIe form factor | Proposed — not yet funded |

---

## 7. Known Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| README claims exceed implementation (YOLOv8, Redis, NL query) | High | Update README before judge review; frame as "next stage" |
| REST track/alert endpoints may return empty state | High | Wire tracker output into REST stores or remove endpoints from demo flow |
| Demo runs on localhost with no fallback | Medium | Capture screenshots + screen recording as backup |
| Unidentified GPU brands/models in inventory | Medium | Physical inspection before committing to rack slots |
| 8 GB VRAM limits model scale | Low | Known constraint; work within it or use quantization |
| No tests in repo | Low | Add focused tracker unit tests if time allows |

---

## 8. AI Prompt Library

Copy any of these into your session after this document to start a focused conversation.

### Architecture Review
> Review this snapshot and identify the highest-impact changes for demo reliability and technical credibility within 24–48 hours. Separate must-fix issues from nice-to-have improvements.

### Algorithm / Fusion Review
> Given the current nearest-neighbor/Kalman-style tracker and heuristic evasion scoring, recommend a defensible short-term fusion approach for a demo. Explain how to describe the algorithm accurately to technical judges without overstating the implementation.

### Hardware Platform Review
> Review the GPU inventory and proposed rack configurations. Given the NATSEC CV workloads described (YOLOv8, DDP training, real-time inference), validate the rack assignment logic, identify risks, and suggest any improvements to the hardware strategy.

### GPU Upgrade Planning
> Based on the existing RTX 3070/3070 Ti inventory and the proposed L40S + RTX 6000 Ada upgrade, what is the recommended procurement sequence? What should be purchased first to maximize capability per dollar for on-premise air-gapped NATSEC computer vision workloads?

### Demo Script Generation
> Generate a step-by-step demo script for a hackathon judge audience. Include: what to show, what to say at each step, expected observations, and fallback lines if something breaks.

### PM / Backlog Generation
> Convert this snapshot into a prioritized implementation backlog with acceptance criteria, dependencies, and estimated effort in hours. Focus on demo-readiness first, then technical quality.

### Judge Narrative / Pitch
> Write a concise judge-facing technical narrative for the xTech National Security Hackathon. Cover: the problem, the approach, the live demo flow, and why this capability matters for contested-environment operations.

### Code Review
> Review the repo for inconsistencies between README claims and implementation. Focus on demo-blocking bugs, missing API wiring, and documentation gaps.

---

## 9. Snapshot History

| Version | Date | File | Key Changes |
|---------|------|------|-------------|
| v001 (unversioned) | 2026-05-02 | `2026-05-02-project-snapshot.md` | Software-only: architecture, gaps, roadmap, risks |
| v002 | 2026-05-02 | `v002-2026-05-02-full-platform.md` | Added GPU hardware inventory, rack configs, decisions log, prompt library |

---

## 10. Definitions

| Term | Definition |
|------|-----------|
| Detection | A single observation from one sensor modality at a point in time |
| Track | A fused estimate of a target's state (position, velocity, confidence) maintained across observations |
| Sensor modality | EO (electro-optical), IR (infrared), RF (radio frequency), or future class |
| Track custody | Continuous ability to associate future observations with the same target |
| Evasion candidate | A track whose detection pattern suggests abnormal dropout or maneuver behavior (currently: >60% dropout threshold) |
| Confidence | A score representing observation quality and multi-sensor support; current implementation uses lightweight smoothing — not a calibrated probability |
| Air-gappable | Can operate without internet connectivity; relevant to NATSEC deployment requirements |

---

## 11. Response Log

*Use this section to record AI/reviewer responses to this snapshot. Save responses as separate dated files and link here.*

| Date | Source | Prompt Used | Response File | Key Accepted Actions |
|------|--------|-------------|---------------|----------------------|
| — | — | — | — | — |
