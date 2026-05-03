# Node: Tahoe — Head Node + Network

**Role:** Head node / GPU compute server + TAHOE secure network gateway  
**Hardware:** Supermicro (Xeon-based)  
**GPU target:** 6× NVIDIA GeForce RTX 3070  
**Network:** TAHOE — TP-Link DECO mesh, secured via Ethernet Sharing from xcasa (mamba)

---

## Directory Structure

```
platform/nodes/tahoe/
├── README.md          ← this file
├── photos/            ← hardware photos (server, GPUs, rack install)
└── network/           ← TAHOE network config, DECO setup docs
```

## Network Architecture

```
Internet
    ↓  (Ethernet — en9 on mamba)
mamba (xcasa)
    ↓  Internet Sharing → Wi-Fi soft-AP
DECO mesh router
    ↓  TAHOE secure Wi-Fi network
Team devices / phones
```

## Photo Sync

Drop Supermicro / DECO / TAHOE setup photos into `photos/` here,
or add to the `810-26-NATSEC-CV` album in Photos and run:

```bash
make collect && make build-gallery && make atlas
```

## Node Naming Convention

California lakes — `tahoe`, `sequoia`, `shasta`, `crater`, `mono` …
