# NATSEC-CV Hardware Collection — Photo Intake

Generic drop zone for all NATSEC-CV hardware photos. Not node-specific.
Drop anything here: servers, GPUs, drones, sensors, networking gear, racks.

Syncs from iCloud shared album **APPLE-COLLECTION**:
`https://www.icloud.com/sharedalbum/#B1q5ON9t3GK4JB9`

---

## Structure

```
platform/collection/
├── inbox/        ← DROP PHOTOS HERE (HEIC, JPG, PNG, MOV)
├── processed/    ← auto-moved here after analysis
└── manifests/    ← auto-generated inventory docs (one per batch)
```

## How to Sync from iCloud

```bash
# From iCloud Drive on macOS (if album is saved locally):
cp ~/Library/Mobile\ Documents/com~apple~CloudDocs/APPLE-COLLECTION/* \
  platform/collection/inbox/

# Or download from iCloud web and drop into inbox/
```

## How to Process (manual)

```bash
./scripts/ingest-collection.sh
```

This will:
1. Find all new HEIC/JPG/PNG in `inbox/`
2. Convert HEIC → JPEG
3. Generate a dated manifest in `manifests/`
4. Move originals to `processed/`

## Auto-Detection

Claude Code is configured (via `.claude/settings.json`) to check `inbox/`
for new unprocessed files at the start of each session and announce what it finds.

## Category Tags (used in manifests)

Claude infers category from photo content. Known categories:

| Tag | Description |
|-----|-------------|
| `gpu` | GPU cards, mining rigs, open-air frames |
| `server` | Rack servers, head nodes, blade chassis |
| `sensor` | Cameras, IR sensors, RF sensors, LiDAR |
| `drone` | UAV airframes, payloads, ground stations |
| `network` | Switches, NICs, cables, patch panels |
| `psu` | Power supplies, PDUs, UPS units |
| `unknown` | Unrecognized — flagged for manual review |
