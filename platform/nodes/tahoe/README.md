# Node: Tahoe — Head Node

**Role:** Head node / GPU compute server  
**Hardware:** Supermicro (Xeon-based)  
**GPU target:** 6× NVIDIA GeForce RTX 3070  
**Project:** CRISP AI — NATSEC-CV / xTech National Security Hackathon

---

## Directory Structure

```
platform/nodes/tahoe/
├── README.md          ← this file
├── photos/            ← iCloud sync target (album: APPLE-COLLECTION)
└── docs/              ← slot assignments, config notes, wiring diagrams
```

## Photo Sync

Photos are sourced from the iCloud shared album **APPLE-COLLECTION**.

To sync locally on macOS:

```bash
# Option 1: iCloud Drive (if album is saved to iCloud Drive)
cp -r ~/Library/Mobile\ Documents/com~apple~CloudDocs/APPLE-COLLECTION/* \
  platform/nodes/tahoe/photos/

# Option 2: Manual — download from iCloud web, drop into photos/
# https://www.icloud.com/sharedalbum/#B1q5ON9t3GK4JB9
```

> Large video files (*.MOV, *.MP4) are gitignored. Add them locally for reference but do not commit.

## Node Nomenclature

Nodes in this cluster are named after California lakes/reservoirs — geographically rooted, easy to remember, avoids vendor names:

| Node | Role | Status |
|------|------|--------|
| `tahoe` | Head node (Supermicro/Xeon + 6× RTX 3070) | In configuration |

## Hardware Notes

- Server: Supermicro (model TBD from photos)
- CPU: Intel Xeon (config TBD)
- GPU slots: PCIe — target 6× RTX 3070 (TBD pending photo review)
- PSU: TBD — must verify headroom for ~1,320 W GPU load (6× 220 W)
