# PR-002 — SIERRA: Secure Customer Demo Network with Authenticated Gallery

| Field | Value |
|-------|-------|
| GitHub PR | [#2](https://github.com/sachin-crispai/xtech-natsec-cv/pull/2) |
| Branch | `feature/sierra-secure-gallery` |
| Status | **OPEN** |
| Created | 2026-05-03 |
| Merged | — |

---

## Description

Adds a secure, isolated customer-facing demo environment called **SIERRA** running on the TAHOE rig. Customers join a password-protected Wi-Fi network and authenticate per-session to view the gallery — without accessing the ops team network.

## Architecture

```
Internet (Ethernet en9)
        ↓
   TAHOE rig (mamba)
        ├── TAHOE/natsec  — ops team, open gallery (existing)
        └── SIERRA        — prospective customers, authenticated only
                Layer 1: WPA2 Wi-Fi password to join SIERRA
                Layer 2: nginx basic auth (per-guest credentials)
                Layer 3: IP allowlist — 192.168.2.0/24 only, deny all
```

**Customer URL:** `http://tahoe/gallery/` — unreachable outside SIERRA subnet

## Commands Added

| Command | Action |
|---------|--------|
| `make sierra-start` | Start SIERRA hotspot + nginx + dnsmasq |
| `make sierra-stop` | Clean teardown |
| `make add-guest NAME=john` | Create credential + print QR code for phone |
| `make list-guests` | Show active guests |
| `make revoke-guest NAME=john` | Remove one guest |
| `make revoke-all-guests` | Lock gallery after demo |

## Customer Onboarding Flow

1. `make sierra-start` — SIERRA network goes live
2. `make add-guest NAME=john` — prints credentials + QR code
3. Customer scans QR → joins SIERRA Wi-Fi → gallery opens authenticated
4. `make revoke-all-guests` — lock after meeting

## Test Plan

- [ ] `make sierra-start` starts SIERRA SSID (visible on phone)
- [ ] `make add-guest NAME=test` prints credentials + QR
- [ ] Phone joins SIERRA, opens `http://tahoe/gallery/`, prompts for login
- [ ] Valid credentials → gallery loads
- [ ] Invalid credentials → 401
- [ ] From outside SIERRA (e.g. regular Wi-Fi) → 403
- [ ] `make revoke-all-guests` → gallery returns 401 for all

## Notes

<!-- Add review feedback, decisions, and follow-up actions here -->
