# GPU Platform — Hardware Inventory

**Survey date:** 2026-05-01  
**Location:** CrispAI office  
**Surveyors:** Ken Choi, Sachin Naik  
**Source:** Physical inspection photos (IMG_0074 – IMG_0083)

---

## Summary

| Component | Model | Qty (confirmed) | Notes |
|-----------|-------|-----------------|-------|
| GPU | EVGA GeForce RTX 3070 Ti | 7+ | Rig 3 (IMG_0081) — all EVGA XC3 / FTW3 variant |
| GPU | EVGA GeForce RTX 3070 | 4+ | Rigs 1 & 2 (IMG_0076, 0082, 0083) |
| GPU | MSI GeForce RTX (30-series) | 2+ | Rig 1 (IMG_0076, 0077) — exact model unclear |
| GPU | XFX GeForce/Radeon (30-series) | 2+ | Rig 2 (IMG_0077) — exact model unclear |
| Rig frame | Open-air GPU mining rack | 4 | Custom steel frames, stackable |
| PSU | Multi-PSU per rig (ATX/Server) | ~8+ | Yellow-tagged units; multiple per rig |

**Total GPUs (confirmed visible):** ~15–18 across all rigs  
**Total rigs:** 4 open-air frames (some stacked 2-high)

---

## Detailed Rig Breakdown

### Rig 1 — Mixed EVGA / MSI rack (floor, IMG_0076)
- ~6 GPUs in open-air frame
- Right side: 2× **EVGA GeForce RTX 3070**
- Center: 2× **MSI GeForce RTX** (30-series, model TBD)
- Left side: 2× brand unclear (dark shroud)
- PCIe risers with blue cables
- Status: laid flat on floor, likely being assembled/reconfigured

### Rig 2 — XFX / MSI rack (IMG_0077)
- ~4–5 GPUs in open-air frame
- Left: 2× **XFX** branded GPUs
- Center/right: 2× **MSI GeForce RTX**
- 1 additional standalone GPU on top of cardboard box (different cooler style, model TBD)
- Status: laid flat, likely being assembled

### Rig 3 — EVGA RTX 3070 Ti rack (IMG_0078, 0079, 0081 — most complete)
- **7× EVGA GeForce RTX 3070 Ti** clearly visible (IMG_0081 confirms all 7)
- All cards appear to be the same EVGA 3070 Ti SKU (XC3 Ultra or FTW3)
- 2-shelf open-air rack with PSUs on bottom shelf
- PSUs tagged with yellow labels
- PCIe risers with blue and yellow cables
- Status: assembled, fully wired

### Rig 4 — EVGA RTX rack (IMG_0082, 0083)
- 4–5× **EVGA GeForce RTX** cards (includes at least 1× RTX 3070 Ti confirmed on right)
- Blue and yellow PCIe riser cables
- Rack-mounted under a shelf/desk
- Status: installed and wired

---

## Infrastructure Notes

- All rigs use **PCIe riser extenders** (standard x1-to-x16 risers)
- Wiring: blue and yellow molex/PCIe cables throughout
- Power: multiple ATX PSUs per rig, some with yellow caution tags
- Environment: office space (carpet), not a purpose-built data center
- Cooling: open-air frames, no dedicated rack cooling observed
- One MOV video (IMG_0072.MOV) not yet reviewed — may contain additional context

---

## Hackathon Build — Two Racks from Existing Inventory

### GPU Selection — Pick 12 from What's On Hand

Ranked by performance; pick in order until you have 12:

| Pick | GPU | VRAM | Mem BW | TDP | Count on hand |
|------|-----|------|--------|-----|---------------|
| 1–7 | **EVGA GeForce RTX 3070 Ti** | 8 GB GDDR6X | 448 GB/s | 290 W | 7 confirmed (IMG_0081) |
| 8–11 | **EVGA GeForce RTX 3070** | 8 GB GDDR6 | 448 GB/s | 220 W | 4+ confirmed |
| 12 | **MSI GeForce RTX 30-series** | 8 GB (assumed) | ~448 GB/s | ~220–290 W | 2 on hand (model TBD) |

> **Spare / bench:** Set XFX cards aside — model unconfirmed, may be different VRAM tier. Confirm before committing to a rack slot.

### Two-Rack Assignment

#### Rack A — Primary (training + heavy inference)
6× EVGA RTX 3070 Ti — identical cards, cleanest config

| Slot | GPU | VRAM | Power |
|------|-----|------|-------|
| 1–6 | EVGA RTX 3070 Ti | 8 GB each → **48 GB total** | ~290 W each → **~1,740 W** |

#### Rack B — Secondary (inference + parallel experiments)
1× RTX 3070 Ti + 4× RTX 3070 + 1× MSI RTX 30-series

| Slot | GPU | VRAM | Power |
|------|-----|------|-------|
| 1 | EVGA RTX 3070 Ti | 8 GB | ~290 W |
| 2–5 | EVGA RTX 3070 × 4 | 8 GB each | ~220 W each |
| 6 | MSI RTX 30-series | 8 GB (est.) | ~220–290 W |
| | **Total** | **48 GB** | **~1,430–1,530 W** |

#### Combined Two-Rack Summary

| | Rack A | Rack B | Total |
|-|--------|--------|-------|
| GPUs | 6× RTX 3070 Ti | 1× 3070 Ti + 4× 3070 + 1× MSI | **12 GPUs** |
| VRAM | 48 GB | 48 GB | **96 GB** |
| GPU power | ~1,740 W | ~1,500 W | **~3,240 W** |
| Est. cost | Already owned | Already owned | **$0** |

### What These Can Run at Hackathon Scale

With 8 GB VRAM per card:

| Workload | Notes |
|----------|-------|
| YOLOv8 / YOLOv9 | Full training + inference |
| ResNet-50/101, EfficientDet | Fine-tuning + inference |
| Detectron2 (instance seg) | Training at batch size 2–4/GPU |
| ViT-S / ViT-B | Inference and fine-tuning |
| CLIP, DINO v2 (ViT-B) | Zero-shot CV pipelines |
| Stable Diffusion 1.5/2.1 | Image augmentation / synthetic data |
| PyTorch DDP | Multi-GPU distributed training across all 12 |
| Whisper (medium/large-v2) | Audio transcription if needed |

> **Won't fit without quantization:** models >8B params, SAM-H, ViT-H, SDXL at full precision.

---

## Proposed Upgrade — Two-Rack GPU Configuration

### Top 12 GPUs Ranked for NATSEC CV Workloads

Ranked by suitability for **computer vision training + inference** in an on-premise, air-gappable PCIe rack environment.

| Rank | GPU | VRAM | Mem BW | TDP | Est. Unit Price | Best For |
|------|-----|------|--------|-----|-----------------|----------|
| 1 | **NVIDIA H200 SXM5** | 141 GB HBM3e | 4.8 TB/s | 700 W | ~$35–40k | Large-model CV training |
| 2 | **NVIDIA B200** | 192 GB HBM3e | 8.0 TB/s | 1,000 W | ~$40–50k | Blackwell flagship; frontier training |
| 3 | **AMD MI300X** | 192 GB HBM3 | 5.3 TB/s | 750 W | ~$15–20k | Max VRAM, AMD ROCm alternative |
| 4 | **NVIDIA H100 PCIe** | 80 GB HBM2e | 2.0 TB/s | 350 W | ~$20–25k | Proven training workhorse, PCIe-native |
| 5 | **NVIDIA L40S** | 48 GB GDDR6 | 864 GB/s | 300 W | ~$10–15k | Best CV balance — training + inference + graphics |
| 6 | **AMD MI350X** | 288 GB HBM3e | 6.0 TB/s | 750 W | ~$20–25k | Largest VRAM available (2025/26) |
| 7 | **NVIDIA RTX 6000 Ada** | 48 GB GDDR6 | 864 GB/s | 300 W | ~$6–8k | Workstation tier, same VRAM as L40S, lower cost |
| 8 | **NVIDIA A100 PCIe 80GB** | 80 GB HBM2 | 1.9 TB/s | 300 W | ~$8–12k (used) | Legacy proven; good bang for used market |
| 9 | **NVIDIA RTX 5090** | 32 GB GDDR7 | 1.79 TB/s | 575 W | ~$2–3k | Consumer Blackwell; fast for smaller CV models |
| 10 | **NVIDIA RTX 4090** | 24 GB GDDR6X | 1.0 TB/s | 450 W | ~$1.5–2k | Budget consumer tier; strong single-GPU CV perf |
| 11 | **NVIDIA L4** | 24 GB GDDR6 | 300 GB/s | 72 W | ~$2–3k | Ultra-low-power inference only; edge/embedded |
| 12 | **NVIDIA H100 NVL PCIe** | 94 GB HBM2e | 3.9 TB/s | 400 W | ~$25–30k | Higher BW variant of H100 PCIe; NVLink-capable |

---

### Recommended Two-Rack Build

Given NATSEC CV workloads (CV model training + real-time inference), standard PCIe rack infrastructure, and air-gap / on-prem requirement:

#### Rack 1 — Training Rack (6× NVIDIA L40S or H100 PCIe)

| Slot | GPU | VRAM | Power |
|------|-----|------|-------|
| 1–6 | NVIDIA L40S × 6 | 48 GB each / 288 GB total | 300 W each → **1,800 W** |

- Fits standard 2U/4U PCIe server (e.g. Supermicro 4124GS, Dell R750xa)
- 288 GB aggregate VRAM supports training large CV backbone models (ViT-H, DINO v2, SAM)
- Upgrade path: swap for H100 PCIe (same slot, 350W each) for 480 GB HBM total
- Estimated rack GPU cost: **~$60–90k** (L40S) or **~$120–150k** (H100 PCIe)

#### Rack 2 — Inference Rack (6× NVIDIA RTX 6000 Ada)

| Slot | GPU | VRAM | Power |
|------|-----|------|-------|
| 1–6 | NVIDIA RTX 6000 Ada × 6 | 48 GB each / 288 GB total | 300 W each → **1,800 W** |

- Same VRAM and memory bandwidth as L40S at ~50% lower cost
- Full Ada Lovelace tensor cores + hardware RT for CV pipelines
- Optimized for high-throughput batched inference (object detection, segmentation, tracking)
- Estimated rack GPU cost: **~$36–48k**

#### Combined Two-Rack Summary

| | Rack 1 (Training) | Rack 2 (Inference) |
|-|-------------------|---------------------|
| GPU | 6× L40S | 6× RTX 6000 Ada |
| Total VRAM | 288 GB | 288 GB |
| Total GPU power | ~1,800 W | ~1,800 W |
| Est. GPU cost | ~$60–90k | ~$36–48k |
| **Combined** | | **~$96–138k** |

> **Power budget note:** Each rack needs ~3–4 kW total (GPUs + CPUs + storage + networking). Standard 208V/30A circuits provide ~6 kW — one circuit per rack is sufficient. Liquid cooling or high-airflow rack PDUs recommended for sustained workloads.

---

## Action Items / TODOs

- [ ] Confirm exact MSI and XFX GPU models (need closer photos or serial numbers)
- [ ] Confirm the standalone GPU in Rig 2 (on cardboard box)
- [ ] Review IMG_0072.MOV for additional hardware context
- [ ] Record serial numbers / asset tags for each GPU
- [ ] Confirm PSU make/model and wattage per rig
- [ ] Assess if environment meets thermal/power requirements for sustained compute workloads
- [ ] Document network connectivity (switch, NICs) if applicable

---

## Source Images

| File | Contents |
|------|----------|
| IMG_0074.HEIC | Person (non-hardware) |
| IMG_0075.HEIC | Visitor badges — Ken Choi, Sachin Naik |
| IMG_0076.HEIC | Rig 1 — Mixed GPU rack (top-down, floor) |
| IMG_0077.HEIC | Rig 2 — XFX/MSI GPU rack + standalone GPU |
| IMG_0078.HEIC | Rig 3 — Multi-shelf rack overview |
| IMG_0079.HEIC | Rig 3 — PSU shelf + EVGA RTX wiring detail |
| IMG_0080.HEIC | Rig 3/4 — PSU & motherboard interior |
| IMG_0081.HEIC | Rig 3 — 7× EVGA RTX 3070 Ti (clearest ID) |
| IMG_0082.HEIC | Rig 4 — EVGA RTX rack (installed under shelf) |
| IMG_0083.HEIC | Rig 4 — EVGA RTX rack wiring detail |
| IMG_0072.MOV  | Video — contents not yet reviewed |
| converted/    | JPEG copies of all HEIC files (auto-generated) |
