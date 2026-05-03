#!/usr/bin/env bash
# Sync photos from a public iCloud shared album link directly to inbox/
# No Photos app or osxphotos needed — works via iCloud shared streams API.
#
# Usage:
#   bash scripts/sync-icloud-link.sh [ALBUM_URL]
#   make sync-from-link
#   make sync-from-link ICLOUD_URL="https://www.icloud.com/sharedalbum/#TOKEN"

set -euo pipefail

ALBUM_URL="${1:-${ICLOUD_URL:-}}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INBOX="$REPO_ROOT/platform/collection/inbox"
PROCESSED="$REPO_ROOT/platform/collection/processed"

if [[ -z "$ALBUM_URL" ]]; then
  echo "  ERROR: No URL. Usage: make sync-from-link ICLOUD_URL='https://...'"
  exit 1
fi

mkdir -p "$INBOX"

python3 - "$ALBUM_URL" "$INBOX" "$PROCESSED" << 'PYEOF'
import sys, json, os, re, urllib.request, urllib.error

album_url = sys.argv[1]
inbox     = sys.argv[2]
processed = sys.argv[3]

# ── Helpers ────────────────────────────────────────────────────────────────────
def post(url, payload):
    data = json.dumps(payload).encode()
    req  = urllib.request.Request(url, data=data, headers={
        'Content-Type': 'application/json',
        'Origin':       'https://www.icloud.com',
        'Referer':      'https://www.icloud.com/',
    })
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.loads(r.read())

def download_file(url, dest):
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=30) as r, open(dest, "wb") as f:
        f.write(r.read())
    return os.path.getsize(dest)

# ── Extract token ──────────────────────────────────────────────────────────────
m = re.search(r'#([A-Za-z0-9]+)', album_url)
if not m:
    print("  ERROR: Cannot extract token from URL"); sys.exit(1)
token = m.group(1)
print(f"\n  Token  : {token}")

# ── Discover server ────────────────────────────────────────────────────────────
print("  [1/4] Discovering server...")
try:
    urllib.request.urlopen(urllib.request.Request(
        f"https://sharedstreams.icloud.com/{token}/sharedstreams/webstream",
        data=json.dumps({"streamCtag": None}).encode(),
        headers={"Content-Type": "application/json"}
    ), timeout=5)
    server = "sharedstreams.icloud.com"
except urllib.error.HTTPError as e:
    body   = json.loads(e.read())
    server = body.get("X-Apple-MMe-Host", "")
    if not server:
        print("  ERROR: Could not discover server"); sys.exit(1)
print(f"  Server : {server}")

# ── Fetch photo metadata ───────────────────────────────────────────────────────
print("  [2/4] Fetching photo list...")
stream  = post(f"https://{server}/{token}/sharedstreams/webstream", {"streamCtag": None})
photos  = stream.get("photos", [])
images  = [p for p in photos if p.get("mediaAssetType") != "video"]
videos  = [p for p in photos if p.get("mediaAssetType") == "video"]
print(f"  Album  : {stream.get('streamName','?')}")
print(f"  Total  : {len(photos)}  (images: {len(images)}  videos: {len(videos)})")

# Build checksum → (guid, ext) map — use highest-res derivative per photo
# API returns items keyed by checksum, so we need this reverse mapping
checksum_map = {}   # checksum → {"guid": ..., "ext": ..., "deriv_key": ...}
guid_best    = {}   # guid → (deriv_key, checksum, ext)  — best quality

for p in photos:
    guid   = p.get("photoGuid", "")
    derivs = p.get("derivatives", {})
    is_vid = p.get("mediaAssetType") == "video"

    if is_vid:
        # Pick highest quality video derivative
        for k in ["720p", "360p", "PosterFrame"]:
            if k in derivs and k != "PosterFrame":
                cs = derivs[k].get("checksum", "")
                if cs:
                    checksum_map[cs] = {"guid": guid, "ext": "mov", "key": k}
                    guid_best[guid]  = (k, cs, "mov")
                    break
    else:
        # Pick largest numeric derivative (highest resolution)
        num_keys = [(int(k), k) for k in derivs if k.isdigit()]
        if num_keys:
            _, best_key = max(num_keys)
            cs = derivs[best_key].get("checksum", "")
            if cs:
                checksum_map[cs] = {"guid": guid, "ext": "jpg", "key": best_key}
                guid_best[guid]  = (best_key, cs, "jpg")

# ── Resolve download URLs in batches of 25 ────────────────────────────────────
print("  [3/4] Resolving download URLs...")

guids      = list(guid_best.keys())
url_map    = {}   # checksum → full download URL

batch_size = 25
for i in range(0, len(guids), batch_size):
    batch = guids[i:i+batch_size]
    try:
        resp = post(
            f"https://{server}/{token}/sharedstreams/webasseturls",
            {"photoGuids": batch}
        )
        locations = resp.get("locations", {})
        items     = resp.get("items", {})

        for checksum, info in items.items():
            loc_key  = info.get("url_location", "")
            url_path = info.get("url_path", "")
            scheme   = locations.get(loc_key, {}).get("scheme", "https")
            if loc_key and url_path:
                url_map[checksum] = f"{scheme}://{loc_key}{url_path}"

        print(f"  Batch {i//batch_size + 1}/{(len(guids)-1)//batch_size + 1}: "
              f"{len(url_map)} URLs resolved so far")
    except Exception as e:
        print(f"  Batch {i//batch_size + 1}: error — {e}")

# ── Download ───────────────────────────────────────────────────────────────────
print(f"\n  [4/4] Downloading new photos...")
downloaded = skipped = failed = 0

for guid, (key, checksum, ext) in guid_best.items():
    url = url_map.get(checksum)
    if not url:
        continue

    fname = f"{guid}.{ext}"
    dest  = os.path.join(inbox, fname)
    done  = os.path.join(processed, fname)

    if os.path.exists(dest) or os.path.exists(done):
        skipped += 1
        continue

    try:
        size = download_file(url, dest)
        print(f"  ✓ {guid[:8]}...{ext}  {size//1024} KB")
        downloaded += 1
    except Exception as e:
        print(f"  ✗ {guid[:8]}... {e}")
        failed += 1

print(f"""
  ─────────────────────────────────────
  Downloaded : {downloaded}
  Skipped    : {skipped}  (already synced)
  Failed     : {failed}
  ─────────────────────────────────────""")
if downloaded > 0:
    print("  Run: make ingest-collection")
elif skipped == len(guid_best):
    print("  ✅ All photos already synced — nothing new.")
print()
PYEOF
