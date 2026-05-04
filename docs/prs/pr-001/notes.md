# PR-001 — GPU Hardware Inventory from Physical Survey

| Field | Value |
|-------|-------|
| GitHub PR | [#1](https://github.com/sachin-crispai/xtech-natsec-cv/pull/1) |
| Branch | `platform/gpu-hardware-inventory` |
| Status | **MERGED** |
| Created | 2026-05-02 |
| Merged | 2026-05-03 |
| Surveyors | Ken Choi, Sachin Naik |

---

## Description

Physical survey of CRISP AI office GPU rigs. Converts HEIC photos to JPEG and produces a structured hardware inventory markdown document.

## What Was Merged

- 10 HEIC photos converted to JPEG (`platform/gpu/converted/`)
- `HARDWARE_INVENTORY.md` documenting all identified GPUs, rigs, and infrastructure
- `IMG_0072.MOV` excluded (154 MB — too large for git without LFS)

## Hardware Identified

| Component | Model | Confirmed Qty |
|-----------|-------|---------------|
| GPU | EVGA GeForce RTX 3070 Ti | 7+ |
| GPU | EVGA GeForce RTX 3070 | 4+ |
| GPU | MSI GeForce RTX 30-series | 2+ |
| GPU | XFX 30-series | 2+ |
| Rig frame | Open-air GPU mining rack | 4 |
| PSU | Multi-PSU per rig | ~8+ |

**Total GPUs visible:** ~15–18 across 4 rigs

## Outstanding TODOs (carried forward)

- [ ] Confirm exact MSI and XFX GPU models (need closer photos or serial numbers)
- [ ] Review `IMG_0072.MOV` for additional hardware context
- [ ] Record serial numbers / asset tags per GPU
- [ ] Confirm PSU make/model and wattage
- [ ] Assess thermal/power adequacy for sustained compute workloads

## Notes

Follow-up work (sandal-verified chain-of-custody photos, approved chassis inventory, 2-rack hackathon build) landed in subsequent commits on the same branch before merge.
