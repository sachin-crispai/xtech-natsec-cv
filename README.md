# xTech National Security Hackathon 2026
## CRISP AI — Multi-Sensor Fusion & Target Tracking

**Army FUZE xTech Program | May 2-3, 2026 | SHACK 15, San Francisco**

**Capability Area:** Problem Statement 1 — Sensor Analysis and Integration

---

### Problem We Solve

Modern battlefields generate detections from EO, IR, and RF sensors simultaneously. No single sensor sees everything — targets evade, signals drop, and contested environments degrade coverage. **SensorFuse** automatically correlates detections across modalities into a single, confidence-scored operational picture with persistent target custody.

### What We Built

A real-time multi-sensor fusion pipeline with a tactical dashboard:

- **Sensor Ingestion** — Simulated EO (video), IR, and RF detection feeds via WebSocket
- **Detection Engine** — YOLOv8-based object detection on video frames
- **Fusion Core** — Kalman-filter track association across sensor modalities
- **Evasion Detection** — Pattern analysis to flag targets actively avoiding detection
- **Tactical Display** — Live map + track timeline with NL querying

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SENSOR LAYER                         │
│   EO Camera ──► YOLO Detector                          │
│   IR Sensor  ──► IR Parser        ──► Message Bus      │
│   RF Sensor  ──► RF Parser                             │
└─────────────────────┬───────────────────────────────────┘
                      │ Detection Events
┌─────────────────────▼───────────────────────────────────┐
│                  FUSION CORE                            │
│   Track Association (Kalman + GNN) ──► Track Store     │
│   Confidence Scoring ──► Evasion Analyzer              │
└─────────────────────┬───────────────────────────────────┘
                      │ Fused Tracks (WebSocket)
┌─────────────────────▼───────────────────────────────────┐
│                TACTICAL DASHBOARD                       │
│   Map View │ Track Timeline │ Alert Feed │ NL Query     │
└─────────────────────────────────────────────────────────┘
```

### Quick Start

```bash
# Backend
cd backend
pip install -r requirements.txt
uvicorn api.main:app --reload --port 8000

# Frontend
cd frontend
npm install
npm run dev
```

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Detection | YOLOv8 (Ultralytics), OpenCV |
| Fusion | Kalman Filter, SciPy, NumPy |
| Backend | FastAPI, WebSocket, Redis |
| Frontend | React, Leaflet.js, Recharts |
| Packaging | Docker Compose |

### Evaluation Alignment

| Criterion | Weight | Our Approach |
|-----------|--------|-------------|
| Technical Demo | 35% | Live sensor feed → fusion → map, all real-time |
| Military Impact | 30% | Solves custody loss in contested environments |
| Solution Creativity | 25% | Evasion-pattern detection across modalities |
| Presentation | 10% | NL query interface for non-technical operators |
