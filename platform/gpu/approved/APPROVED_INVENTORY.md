# Approved GPU Chassis — Hardware Inventory

**Survey date:** 2026-05-01  
**Location:** CrispAI office  
**Source:** Approved directory (`platform/gpu/approved/`)  
**Approval method:** Each valid image contains a sandal visible at the bottom of the frame — used as physical presence / chain-of-custody marker  
**Context:** Chassis that have been sorted and collected out for inventory

---

## Image Approval Status

| File | Sandal present | Status | Notes |
|------|---------------|--------|-------|
| IMG_0089.HEIC | ✅ Yes — 1 sandal, bottom center | **APPROVED** | Chassis 3 closeup (tilted) + Chassis 2 partial left |
| IMG_0090.HEIC | ✅ Yes — 1 sandal, bottom right | **APPROVED** | Best wide-angle — all 3 chassis in frame |
| IMG_0091.HEIC | ✅ Yes — 2 sandals, bottom center | **APPROVED** | Chassis 1 (left) + Chassis 2 (right) side by side |
| IMG_0092.HEIC | ✅ Yes — 2 sandals, bottom center | **APPROVED** | Same scene as 0091, clearer labels, partial Chassis 3 far right |
| IMG_0093.HEIC | ✅ Yes — 2 sandals, bottom center | **APPROVED** | Chassis 3 closeup + Chassis 2 partial left |

---

## Chassis Inventory (Slot-by-Slot)

### Chassis 1 — XFX / MSI / Mixed
*Visible in: IMG_0091 (left), IMG_0092 (left), IMG_0090 (far left, partial)*  
*Form factor: Open-air steel mining frame, 6 slots*

| Slot | Brand | Model | VRAM | Confidence | Source |
|------|-------|-------|------|------------|--------|
| 1 (top) | XFX | GeForce RTX — model TBD | 8 GB est. | Medium — XFX label readable, model obscured | 0091, 0092 |
| 2 | XFX | GeForce RTX — model TBD | 8 GB est. | Medium — XFX label readable, dark red/black shroud | 0091, 0092 |
| 3 | MSI | GeForce RTX — model TBD | 8 GB est. | High — MSI dragon logo visible | 0091, 0092 |
| 4 | Unknown | GeForce RTX — model TBD | 8 GB est. | Low — silver/gray shroud, brand not readable | 0091, 0092 |
| 5 | Unknown | GeForce RTX — model TBD | 8 GB est. | Low — silver/gray shroud, brand not readable | 0091, 0092 |
| 6 (bottom) | Unknown | GeForce RTX — model TBD | 8 GB est. | Low — partially cut off in all frames | 0092 |

**Chassis 1 subtotal: 6 GPUs**  
Confirmed brands: XFX ×2, MSI ×1 | Unconfirmed brand: ×3

---

### Chassis 2 — EVGA RTX 3070 / MSI Mixed
*Visible in: IMG_0090 (center), IMG_0091 (right), IMG_0092 (center/right), IMG_0089 (left partial), IMG_0093 (left partial)*  
*Form factor: Open-air steel mining frame, 6 slots*

| Slot | Brand | Model | VRAM | Confidence | Source |
|------|-------|-------|------|------------|--------|
| 1 (top) | EVGA | GeForce RTX 3070 | 8 GB GDDR6 | **High** — label clearly reads "EVGA \| GEFORCE RTX 3070" | 0090, 0091, 0092, 0093 |
| 2 | EVGA | GeForce RTX 3070 | 8 GB GDDR6 | **High** — same label confirmed across multiple frames | 0090, 0091, 0092, 0093 |
| 3 | MSI | GeForce RTX — model TBD | 8 GB est. | High — MSI branding visible, model text obscured | 0090, 0091, 0092 |
| 4 | MSI | GeForce RTX — model TBD | 8 GB est. | High — MSI branding visible, model text obscured | 0090, 0091, 0092 |
| 5 | Unknown | GeForce RTX — model TBD | 8 GB est. | Medium — "GEFORCE RTX" label readable, brand unclear | 0090, 0091 |
| 6 (bottom) | Unknown | GeForce RTX — model TBD | 8 GB est. | Medium — "GEFORCE RTX" label readable, brand unclear | 0090 |

**Chassis 2 subtotal: 6 GPUs**  
Confirmed: EVGA RTX 3070 ×2, MSI RTX ×2 | Unconfirmed brand: ×2

---

### Chassis 3 — EVGA All-in (RTX 3070 + 3070 Ti)
*Visible in: IMG_0089 (center, tilted), IMG_0093 (center, tilted), IMG_0090 (right), IMG_0092 (far right, partial)*  
*Form factor: Open-air steel mining frame, 6 slots*

| Slot | Brand | Model | VRAM | Confidence | Source |
|------|-------|-------|------|------------|--------|
| 1 (top) | EVGA | GeForce RTX 3070 | 8 GB GDDR6 | **High** — "EVGA \| GEFORCE RTX 3070" readable | 0093, 0090 |
| 2 | EVGA | GeForce RTX 3070 | 8 GB GDDR6 | **High** — same label confirmed | 0093, 0090 |
| 3 | EVGA | GeForce RTX — 3070 or 3070 Ti | 8 GB | Medium — EVGA confirmed, model partially obscured by angle | 0089, 0093 |
| 4 | EVGA | GeForce RTX 3070 Ti | 8 GB GDDR6X | **High** — "EVGA \| GEFORCE RTX 3070 Ti" readable | 0089, 0093 |
| 5 | EVGA | GeForce RTX 3070 Ti | 8 GB GDDR6X | **High** — label confirmed across two frames | 0089, 0093 |
| 6 (bottom) | EVGA | GeForce RTX 3070 Ti | 8 GB GDDR6X | **High** — bottom card clearly labeled 3070 Ti | 0089, 0093 |

**Chassis 3 subtotal: 6 GPUs**  
Confirmed: EVGA RTX 3070 ×2, EVGA RTX 3070 Ti ×3, EVGA RTX (model TBD) ×1

---

## Non-GPU Hardware (Approved Images)

| Item | Description | Location in Frame | Source |
|------|-------------|-------------------|--------|
| ATX PSU | Standalone power supply, brand unclear (Corsair / EVGA style) | Right of Chassis 3 | IMG_0089, 0093 |
| Aluminum flight case | Metal carry case, closed, unknown contents | Far right of scene | IMG_0089, 0093 |
| Open-air mining frames | Steel GPU rig frames (3 confirmed, 6 slots each) | All chassis | All images |

---

## Consolidated GPU Count (Approved Images Only)

| GPU Model | Brand | Qty | VRAM | Confidence |
|-----------|-------|-----|------|------------|
| GeForce RTX 3070 | EVGA | **4** | 8 GB GDDR6 | High |
| GeForce RTX 3070 Ti | EVGA | **3** | 8 GB GDDR6X | High |
| GeForce RTX (model TBD) | EVGA | 1 | 8 GB est. | Medium |
| GeForce RTX (model TBD) | MSI | 3 | 8 GB est. | High brand, low model |
| GeForce RTX (model TBD) | XFX | 2 | 8 GB est. | Medium brand, low model |
| GeForce RTX (model TBD) | Unknown | 5 | 8 GB est. | Low |
| **TOTAL** | | **18** | **144 GB est.** | |

> **Note:** All GPUs are 8 GB class. RTX 3070 uses GDDR6; RTX 3070 Ti uses GDDR6X (slightly higher bandwidth). Unconfirmed brand/model cards need physical inspection or closer photos to ID.

---

## What Needs Follow-Up

- [ ] Photograph each unidentified card's IO bracket or PCB sticker for model/serial
- [ ] Confirm XFX model — likely RTX 3070 or 3080, but could differ
- [ ] Confirm MSI model — same bracket approach recommended
- [ ] Confirm the 5 unbranded "GeForce RTX" cards — silver shroud suggests ASUS, Gigabyte, or Zotac
- [ ] Confirm Chassis 3, Slot 3 — 3070 or 3070 Ti (currently angle-obscured)
- [ ] Inspect standalone PSU model + wattage
- [ ] Document aluminum case contents
