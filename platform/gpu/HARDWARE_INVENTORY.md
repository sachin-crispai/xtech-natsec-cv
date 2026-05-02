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
