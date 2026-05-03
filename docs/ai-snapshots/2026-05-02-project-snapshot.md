# Project Snapshot: CRISP AI SensorFuse

**Snapshot date:** 2026-05-02  
**Project:** xTech National Security Hackathon 2026, CRISP AI, SensorFuse  
**Capability area:** Sensor analysis and integration  
**Intended consumers:** ChatGPT, Claude Desktop, Gemini, human technical reviewers, PM reviewers  
**Snapshot purpose:** Capture current progress, intended future progress, open questions, and review prompts in a portable form that can be versioned with the repository.

## 1. Executive Summary

SensorFuse is a real-time multi-sensor fusion and target tracking prototype for the Army FUZE xTech National Security Hackathon. The project demonstrates how EO, IR, and RF detections can be correlated into a single operational picture with confidence scoring, persistent track custody, evasion indications, and a tactical dashboard.

The current repository contains a working FastAPI backend, simulated sensor feeds, a nearest-neighbor/Kalman-style fusion tracker, WebSocket track streaming, and a React tactical dashboard. The prototype appears optimized for hackathon demonstration rather than production deployment. Several README claims, such as YOLOv8 video detection, Redis persistence, and natural-language querying, are currently architectural intentions or planned demo capabilities rather than fully implemented features in the checked-in code.

## 2. Problem Statement

Modern operating environments may produce fragmented detections from multiple sensor modalities. A single sensor can lose sight of a target because of terrain, weather, countermeasures, sensor degradation, or intentional evasion. The project goal is to correlate detections across modalities and maintain target custody with operator-readable confidence and alerting.

Primary value proposition:

- Fuse EO, IR, and RF observations into persistent tracks.
- Maintain target custody when individual sensor feeds degrade.
- Surface confidence and evasion indicators to operators.
- Present results in a tactical dashboard suitable for rapid demonstration.

## 3. Target Users

- Hackathon judges evaluating technical demo quality, mission impact, creativity, and presentation.
- Military or defense technical reviewers assessing relevance to sensor fusion and contested-environment operations.
- Software engineers extending the prototype.
- AI research assistants helping refine algorithms, architecture, demo strategy, and proposal language.

## 4. Current Repository Map

```text
.
├── README.md                         # Primary project overview and quick start
├── backend/                          # FastAPI backend, event bus, simulator, fusion tracker
│   ├── api/
│   │   ├── main.py                   # App setup, startup tasks, websocket broadcasting
│   │   └── routers/                  # Sensors, tracks, alerts API routes
│   ├── core/
│   │   ├── event_bus.py              # In-process event bus
│   │   └── models.py                 # Pydantic Detection, Track, Alert models
│   ├── fusion/
│   │   └── tracker.py                # Multi-sensor association and track update logic
│   ├── sensors/
│   │   └── simulator.py              # Simulated EO, IR, RF target detections
│   ├── requirements.txt
│   └── Dockerfile
├── frontend/                         # React/Vite tactical dashboard
│   ├── src/
│   │   ├── App.tsx                   # Main dashboard layout
│   │   ├── components/               # Map, status bar, track panel, alert feed
│   │   ├── hooks/useWebSocket.ts     # Track websocket client
│   │   ├── store/useTrackStore.ts    # Client state
│   │   └── types.ts
│   ├── package.json
│   └── Dockerfile
├── platform/gpu/                     # Hardware inventory and image evidence
├── rfi/                              # xTech Hackathon RFI PDF
├── data/                             # Data directory, contents not assessed in this snapshot
├── scripts/                          # Script directory, contents not assessed in this snapshot
└── docs/ai-snapshots/                # Versioned AI/PM handoff snapshots
```

## 5. Current Implementation Status

### Backend

Implemented:

- FastAPI application with permissive CORS.
- Startup tasks for the simulator, tracker, and track-update websocket broadcast loop.
- `/health` endpoint reporting service status and active track count.
- `/ws/tracks` websocket endpoint for track state streaming.
- Router files for sensors, tracks, and alerts.
- Pydantic models for `Detection`, `Track`, and `Alert`.
- In-process event bus pattern.
- Simulated moving targets and EO/IR/RF detection generation.
- Track association using a nearest-neighbor distance threshold.
- Lightweight Kalman-like smoothing for fused track position and velocity.
- Evasion scoring based on detection dropout over a recent time window.
- Alert publication for new tracks, multi-sensor confirmation, and evasion detection.

Important current gaps:

- Track router has an in-memory `_track_store`, but the tracker does not appear to call `tracks.update_store`, so `/api/tracks/` may not reflect live websocket state without additional wiring.
- Alert router has an `alert_queue`, but tracker alert publication does not appear wired into `alerts.push_alert`, so `/api/alerts/` may remain empty unless another listener exists.
- README mentions Redis, YOLOv8, OpenCV, Leaflet, Recharts, and natural-language querying, but the visible code currently centers on simulator-driven detections and websocket dashboard updates.
- `@app.on_event("startup")` is functional but may trigger deprecation warnings in modern FastAPI versions; lifespan handlers may be preferable later.

### Frontend

Implemented:

- React app shell with `StatusBar`, `TrackPanel`, `TacticalMap`, and `AlertFeed`.
- WebSocket hook for live track updates.
- Client-side store for tracks and sensors.
- Sensor list fetch from `http://localhost:8000/api/sensors/`.
- Vite/TypeScript project structure.

Important current gaps:

- The frontend uses hardcoded localhost backend URLs, which is fine for local demo but should become environment-configurable for deployment.
- The snapshot did not verify whether the UI renders correctly or whether all components handle empty/error states.
- Natural-language querying is listed in the README but not confirmed in the visible frontend files.

### Platform And Evidence

Implemented:

- GPU hardware inventory materials exist under `platform/gpu/inventory/` and `platform/gpu/approved/`.
- Image evidence and inventory markdown files are present.

Important current note:

- The git working tree currently shows deleted files under the old `platform/gpu/` path and untracked files under `platform/gpu/inventory/`. This looks like a move or reorganization in progress. Do not revert those changes without explicit owner approval.

## 6. Current Demo Narrative

The strongest current demo story is:

1. Simulated EO, IR, and RF sensors generate detections over a shared area of operations.
2. The backend publishes detections through an event bus.
3. The fusion tracker associates detections into persistent tracks.
4. The dashboard receives live fused tracks over websocket.
5. The operator sees track confidence, sensor modality confirmation, and evasion indicators.

The project should be presented honestly as a prototype where the fusion and dashboard path is the working core, while real video detection, production sensor adapters, persistence, and natural-language querying are next-stage extensions unless implemented before presentation.

## 7. Known Assumptions

- Simulated sensor data is acceptable for the hackathon demonstration baseline.
- Track association can initially use geographic proximity rather than a full probabilistic multi-hypothesis tracker.
- Evasion detection can initially be heuristic and explainable rather than learned.
- The project optimizes for clear mission demonstration and technical credibility over production hardening.
- The repo may include active file moves in `platform/gpu`; future agents should avoid destructive cleanup unless requested.

## 8. Known Risks

- **Architecture drift:** README claims may exceed current implementation. Align documentation before judging or external review.
- **API/store mismatch:** REST endpoints for tracks and alerts may not reflect live state unless event-bus subscribers update those stores.
- **Demo fragility:** Hardcoded localhost URLs and startup assumptions may break outside the local dev setup.
- **Algorithm credibility:** Current fusion logic is lightweight and explainable but may need clearer language to avoid overstating Kalman/GNN sophistication.
- **Testing gap:** No tests were assessed in this snapshot. Add focused backend tests for association, pruning, and alert publication if time allows.
- **State management:** In-process event bus and memory stores are acceptable for demo but not suitable for distributed deployment.

## 9. Near-Term Priorities

1. Wire tracker state into `/api/tracks/` or remove/clarify the REST endpoint if websocket is the intended source of truth.
2. Wire alerts into `/api/alerts/` and ensure the frontend alert feed receives real alert data.
3. Add environment-based backend URL configuration for the frontend.
4. Run the backend and frontend together and capture a short demo checklist.
5. Update README claims so implemented, simulated, and planned capabilities are clearly separated.
6. Add minimal tests for the fusion tracker and event bus behavior.
7. Create a judge-facing one-page technical explanation of the fusion/evasion logic.

## 10. Future Roadmap

### Demo-Ready Roadmap

- Confirm local startup through `docker-compose` or documented two-terminal commands.
- Ensure live tracks appear on the dashboard within seconds.
- Ensure at least one evasion scenario is visible and explainable.
- Add a simple demo script with expected observations and fallback screenshots.
- Add presentation notes mapping implementation to xTech evaluation criteria.

### Technical Roadmap

- Replace simulated EO detections with actual video-frame object detections.
- Add real or recorded IR/RF adapter interfaces.
- Replace proximity-only association with a more rigorous probabilistic tracker or documented Kalman implementation.
- Persist tracks and alerts in Redis or another store.
- Add track history playback and export.
- Add natural-language querying once track and alert state are reliable.
- Add authentication, deployment configuration, and observability if moving beyond demo.

### Research Roadmap

- Compare nearest-neighbor, JPDA, MHT, factor graph, and learned association approaches for multi-sensor fusion.
- Assess uncertainty modeling and covariance propagation across sensor types.
- Develop a better evasion model using missed-detection patterns, maneuver anomalies, and sensor coverage expectations.
- Evaluate how to explain fusion confidence to non-technical operators without overstating certainty.

## 11. Questions For AI Reviewers

Use this section when pasting into ChatGPT, Claude, or Gemini.

### Architecture Review Prompt

Given this project snapshot, review the architecture for a hackathon-grade multi-sensor fusion prototype. Identify the highest-impact changes that improve demo reliability and technical credibility within 24 to 48 hours. Separate must-fix issues from nice-to-have improvements.

### Algorithm Review Prompt

Given the current nearest-neighbor/Kalman-style tracker and heuristic evasion scoring, recommend a defensible short-term fusion approach suitable for a demo. Explain how to describe the algorithm accurately to technical judges without overstating the implementation.

### Product And PM Review Prompt

Convert this snapshot into a requirements-and-response plan. Identify project objectives, acceptance criteria, dependencies, risks, open questions, and a prioritized implementation backlog.

### Presentation Review Prompt

Create a concise judge-facing narrative for the xTech National Security Hackathon. The narrative should explain the problem, the technical approach, the live demo flow, and why the capability matters for contested environments.

### Code Review Prompt

Review the repo for inconsistencies between README claims and implementation. Focus on bugs, demo blockers, missing tests, and areas where documentation should be clarified.

## 12. Accepted Definitions

- **Detection:** A single observation from one sensor modality.
- **Track:** A fused estimate of a target over time.
- **Sensor modality:** EO, IR, RF, or future sensor class.
- **Track custody:** Continued ability to associate future observations with the same target.
- **Evasion candidate:** A track whose detection pattern suggests abnormal dropout or maneuver behavior.
- **Confidence:** A score representing observation quality and multi-sensor support; current implementation uses lightweight smoothing and should not be described as calibrated probability.

## 13. Decision Log

| Date | Decision | Rationale | Status |
|------|----------|-----------|--------|
| 2026-05-02 | Store AI handoff snapshots under `docs/ai-snapshots/`. | Keeps AI/PM requirements and responses versioned with the repo without mixing them into runtime code. | Accepted |
| 2026-05-02 | Use dated markdown files for snapshots and responses. | ISO dates sort naturally and work across GitHub, ChatGPT, Claude Desktop, and Gemini. | Accepted |

## 14. Response Log Template

Use this section in future response files.

```markdown
# AI Review Response: <topic>

**Date:** YYYY-MM-DD
**Source snapshot:** docs/ai-snapshots/YYYY-MM-DD-project-snapshot.md
**AI/tool used:** ChatGPT / Claude / Gemini / human reviewer
**Prompt used:** <paste or summarize prompt>

## Summary

## Recommendations

## Accepted Actions

## Rejected Or Deferred Actions

## Follow-Up Questions

## Links To Resulting Changes
```

## 15. Next Snapshot Guidance

The next snapshot should be created after any substantial implementation or demo-readiness work. At minimum, update:

- What changed since this snapshot.
- Which README claims are now implemented versus planned.
- Whether backend REST endpoints and websocket feeds are consistent.
- Whether the frontend was run and visually verified.
- Remaining demo risks.
