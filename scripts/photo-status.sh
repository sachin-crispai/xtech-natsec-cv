#!/usr/bin/env bash
# NATSEC-CV Photo Status — audit the full sync pipeline
# Shows counts at every stage and explains any gaps.
# Usage: make photo-status

set -euo pipefail

PHONE_COUNT="${1:-unknown}"   # optional: pass actual phone count for gap analysis
LIBRARY="/Volumes/GENAI/SUCHIR/autopsy.photoslibrary"
ALBUM="810-26-NATSEC-CV"
INBOX="platform/collection/inbox"
PROCESSED="platform/collection/processed"
VIEW="platform/collection/view"
EXPORT_DB="$INBOX/.osxphotos_export.db"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  NATSEC-CV Photo Status  ·  $(date '+%Y-%m-%d %H:%M')            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ── Stage 1: Photos library (source of truth) ──────────────────────────────────
echo "  ── 1. Photos Library ($ALBUM) ──────────────────────────"

QUERY=$(osxphotos query \
  --library "$LIBRARY" \
  --album "$ALBUM" \
  --json 2>/dev/null)

ALBUM_TOTAL=$(echo "$QUERY" | python3 -c "import sys,json; p=json.load(sys.stdin); print(len(p))" 2>/dev/null || echo 0)
ALBUM_PHOTOS=$(echo "$QUERY" | python3 -c "import sys,json; p=json.load(sys.stdin); print(sum(1 for x in p if not x.get('ismovie')))" 2>/dev/null || echo 0)
ALBUM_VIDEOS=$(echo "$QUERY" | python3 -c "import sys,json; p=json.load(sys.stdin); print(sum(1 for x in p if x.get('ismovie')))" 2>/dev/null || echo 0)
ALBUM_MISSING=$(echo "$QUERY" | python3 -c "import sys,json; p=json.load(sys.stdin); print(sum(1 for x in p if x.get('ismissing')))" 2>/dev/null || echo 0)
ALBUM_ICLOUD=$(echo "$QUERY" | python3 -c "
import sys, json
p = json.load(sys.stdin)
# Photos that exist in iCloud but haven't been downloaded to local disk yet
not_local = sum(1 for x in p if x.get('ismissing') or
    (x.get('iscloudasset') and not x.get('hasadjustments') and x.get('ismissing')))
print(not_local)" 2>/dev/null || echo 0)

printf "  %-32s %s\n" "Total in album:"         "$ALBUM_TOTAL"
printf "  %-32s %s\n" "  ↳ Photos:"             "$ALBUM_PHOTOS"
printf "  %-32s %s\n" "  ↳ Videos:"             "$ALBUM_VIDEOS"
if [ "$ALBUM_MISSING" -gt 0 ]; then
  printf "  %-32s %s  ⚠  still downloading from iCloud\n" "  ↳ Not yet on Mac:" "$ALBUM_MISSING"
else
  printf "  %-32s %s\n" "  ↳ All available locally:" "✓"
fi
echo ""

# ── Stage 2: Export DB (what's been synced) ────────────────────────────────────
echo "  ── 2. Export Database (synced to inbox) ─────────────────"

if [ -f "$EXPORT_DB" ]; then
  DB_COUNT=$(python3 -c "
import sqlite3
conn = sqlite3.connect('$EXPORT_DB')
try:
    n = conn.execute('SELECT COUNT(*) FROM export_data').fetchone()[0]
    print(n)
except:
    print(0)
conn.close()" 2>/dev/null || echo 0)
  printf "  %-32s %s\n" "Previously exported:"  "$DB_COUNT"
  NEVER_SYNCED=$((ALBUM_TOTAL - DB_COUNT))
  if [ "$NEVER_SYNCED" -gt 0 ]; then
    printf "  %-32s %s  ← run: make sync-collection\n" "Not yet synced:" "$NEVER_SYNCED"
  else
    printf "  %-32s %s\n" "Not yet synced:" "0  ✓ all synced"
  fi
else
  echo "  Export DB not found — run: make sync-collection"
  DB_COUNT=0
fi
echo ""

# ── Stage 3: Inbox (waiting to ingest) ────────────────────────────────────────
echo "  ── 3. Inbox (waiting to ingest) ─────────────────────────"
INBOX_IMGS=$(find "$INBOX" -maxdepth 1 -type f \
  \( -iname "*.heic" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
  2>/dev/null | wc -l | tr -d ' ')
INBOX_VIDS=$(find "$INBOX" -maxdepth 1 -type f \
  \( -iname "*.mov" -o -iname "*.mp4" \) \
  2>/dev/null | wc -l | tr -d ' ')
INBOX_TOTAL=$((INBOX_IMGS + INBOX_VIDS))
printf "  %-32s %s\n" "Images:" "$INBOX_IMGS"
printf "  %-32s %s\n" "Videos:" "$INBOX_VIDS"
if [ "$INBOX_TOTAL" -gt 0 ]; then
  printf "  %-32s %s  ← run: make ingest-collection\n" "Ready to ingest:" "$INBOX_TOTAL"
else
  printf "  %-32s %s\n" "Inbox:" "empty  ✓"
fi
echo ""

# ── Stage 4: Processed (ingested archive) ─────────────────────────────────────
echo "  ── 4. Processed (ingested archive) ──────────────────────"
PROC_IMGS=$(find "$PROCESSED" -maxdepth 1 -type f \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
  2>/dev/null | wc -l | tr -d ' ')
PROC_HEIC=$(find "$PROCESSED" -maxdepth 1 -type f -iname "*.heic" \
  2>/dev/null | wc -l | tr -d ' ')
PROC_VIDS=$(find "$PROCESSED" -maxdepth 1 -type f \
  \( -iname "*.mov" -o -iname "*.mp4" \) \
  2>/dev/null | wc -l | tr -d ' ')
printf "  %-32s %s\n" "JPEGs (converted):" "$PROC_IMGS"
printf "  %-32s %s\n" "HEICs (originals):" "$PROC_HEIC"
printf "  %-32s %s\n" "Videos:" "$PROC_VIDS"
echo ""

# ── Stage 5: View (gallery) ────────────────────────────────────────────────────
echo "  ── 5. View / Gallery ─────────────────────────────────────"
VIEW_IMGS=$(find "$VIEW" -maxdepth 1 -type f \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
  2>/dev/null | wc -l | tr -d ' ')
VIEW_CLIPS=$(find "$VIEW/clips" -type f -iname "*.mp4" 2>/dev/null | wc -l | tr -d ' ')
VIEW_FRAMES=$(find "$VIEW/frames" -type f -iname "*.jpg" 2>/dev/null | wc -l | tr -d ' ')
printf "  %-32s %s\n" "Images in gallery:" "$VIEW_IMGS"
printf "  %-32s %s\n" "Video clips:" "$VIEW_CLIPS"
printf "  %-32s %s\n" "Extracted frames:" "$VIEW_FRAMES"
echo ""

# ── Summary + gap analysis ─────────────────────────────────────────────────────
echo "  ── Summary ───────────────────────────────────────────────"
if [ "$PHONE_COUNT" != "unknown" ]; then
  PHONE_GAP=$((PHONE_COUNT - ALBUM_TOTAL))
  printf "  %-32s %s\n" "📱 On your device (reported):" "$PHONE_COUNT"
  if [ "$PHONE_GAP" -gt 0 ]; then
    printf "  %-32s %s  ← not yet added to album\n" "  ↳ Gap (phone − album):" "$PHONE_GAP"
  fi
else
  printf "  %-32s %s\n" "📱 On your device:" "(run: make photo-status PHONE=91)"
fi
printf "  %-32s %s\n" "📚 In Photos album (Mac):" "$ALBUM_TOTAL"
printf "  %-32s %s\n" "💾 Synced to disk:" "$DB_COUNT"
printf "  %-32s %s\n" "📁 In processed/:" "$((PROC_IMGS + PROC_VIDS))"
printf "  %-32s %s\n" "🖼  In gallery (view/):" "$VIEW_IMGS"
echo ""

# Gap diagnosis
GAP_ALBUM=$((ALBUM_TOTAL - DB_COUNT))
GAP_GALLERY=$((PROC_IMGS - VIEW_IMGS))

if [ "$ALBUM_MISSING" -gt 0 ]; then
  echo "  ⚠  $ALBUM_MISSING photo(s) in album not yet downloaded from iCloud."
  echo "     Open Photos app and wait for iCloud sync to complete, then:"
  echo "     make sync-collection"
  echo ""
fi

if [ "$GAP_ALBUM" -gt 0 ]; then
  echo "  ⚠  $GAP_ALBUM photo(s) in album not yet synced to disk."
  echo "     Run: make sync-collection"
  echo ""
fi

if [ "$INBOX_TOTAL" -gt 0 ]; then
  echo "  ⚠  $INBOX_TOTAL file(s) in inbox waiting to be ingested."
  echo "     Run: make ingest-collection"
  echo ""
fi

if [ "$GAP_GALLERY" -gt 0 ]; then
  echo "  ⚠  $GAP_GALLERY file(s) in processed/ missing from gallery."
  echo "     Run: make build-gallery"
  echo ""
fi

if [ "$ALBUM_MISSING" = "0" ] && [ "$GAP_ALBUM" = "0" ] && \
   [ "$INBOX_TOTAL" = "0" ] && [ "$GAP_GALLERY" = "0" ]; then
  echo "  ✅ Pipeline is fully in sync."
fi

echo "  ────────────────────────────────────────────────────────"
if [ "$PHONE_COUNT" != "unknown" ] && [ "$PHONE_COUNT" -gt "$ALBUM_TOTAL" ] 2>/dev/null; then
  MISSING_FROM_ALBUM=$((PHONE_COUNT - ALBUM_TOTAL))
  echo "  ⚠  $MISSING_FROM_ALBUM photo(s) on phone not in album yet."
  echo "     Photos app → select photos → + → Add to Album → $ALBUM"
  echo ""
fi
echo "  Tip: make photo-status PHONE=91   (pass your phone count)"
echo "══════════════════════════════════════════════════════════"
echo ""
