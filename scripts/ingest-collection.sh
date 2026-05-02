#!/usr/bin/env bash
# Ingest new photos from platform/collection/inbox/
# Converts HEIC → JPEG, generates a dated manifest, moves originals to processed/
# Usage: ./scripts/ingest-collection.sh [--dry-run]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INBOX="$REPO_ROOT/platform/collection/inbox"
PROCESSED="$REPO_ROOT/platform/collection/processed"
MANIFESTS="$REPO_ROOT/platform/collection/manifests"
DATE="$(date +%Y-%m-%d)"
TIMESTAMP="$(date +%Y-%m-%d-%H%M%S)"
MANIFEST="$MANIFESTS/$TIMESTAMP-intake.md"
DRY_RUN=false

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# ── Helpers ────────────────────────────────────────────────────────────────────
log()  { echo "  $*"; }
warn() { echo "  ⚠  $*"; }

count_files() {
  find "$INBOX" -maxdepth 1 -type f \( \
    -iname "*.heic" -o -iname "*.jpg" -o -iname "*.jpeg" \
    -o -iname "*.png" -o -iname "*.mov" -o -iname "*.mp4" \
  \) | wc -l | tr -d ' '
}

# ── Pre-flight ─────────────────────────────────────────────────────────────────
echo ""
echo "NATSEC-CV Collection Ingest — $DATE"
echo "────────────────────────────────────"

TOTAL=$(count_files)
if [[ "$TOTAL" -eq 0 ]]; then
  echo "  inbox/ is empty — nothing to process."
  echo ""
  exit 0
fi

echo "  Found $TOTAL file(s) in inbox/"
$DRY_RUN && echo "  [DRY RUN — no files will be moved or converted]"
echo ""

# ── Manifest header ────────────────────────────────────────────────────────────
$DRY_RUN || cat > "$MANIFEST" <<HEADER
# Collection Intake — $DATE

**Ingested:** $TIMESTAMP
**Source:** platform/collection/inbox/
**Script:** scripts/ingest-collection.sh

| # | Original File | Converted | Size | Type | Notes |
|---|---------------|-----------|------|------|-------|
HEADER

INDEX=0

# ── Process HEIC ───────────────────────────────────────────────────────────────
while IFS= read -r -d '' FILE; do
  INDEX=$((INDEX + 1))
  BASENAME="$(basename "$FILE")"
  NAME="${BASENAME%.*}"
  EXT="${BASENAME##*.}"
  SIZE="$(du -sh "$FILE" | cut -f1)"

  EXT_UPPER="$(echo "$EXT" | tr '[:lower:]' '[:upper:]')"

  if [[ "$EXT_UPPER" == "HEIC" ]]; then
    JPG="$PROCESSED/${NAME}.jpg"
    log "[$INDEX] $BASENAME → converting to JPEG ($SIZE)"
    if ! $DRY_RUN; then
      sips -s format jpeg "$FILE" --out "$JPG" > /dev/null 2>&1
      mv "$FILE" "$PROCESSED/$BASENAME"
      echo "| $INDEX | \`$BASENAME\` | \`${NAME}.jpg\` | $SIZE | HEIC→JPEG | converted |" >> "$MANIFEST"
    fi

  elif [[ "$EXT_UPPER" == "MOV" || "$EXT_UPPER" == "MP4" || "$EXT_UPPER" == "AVI" ]]; then
    log "[$INDEX] $BASENAME — video, moving to processed/ (not converted) ($SIZE)"
    if ! $DRY_RUN; then
      mv "$FILE" "$PROCESSED/$BASENAME"
      echo "| $INDEX | \`$BASENAME\` | — | $SIZE | video | not converted |" >> "$MANIFEST"
    fi

  else
    log "[$INDEX] $BASENAME — image, moving to processed/ ($SIZE)"
    if ! $DRY_RUN; then
      mv "$FILE" "$PROCESSED/$BASENAME"
      echo "| $INDEX | \`$BASENAME\` | — | $SIZE | image | moved as-is |" >> "$MANIFEST"
    fi
  fi

done < <(find "$INBOX" -maxdepth 1 -type f \( \
  -iname "*.heic" -o -iname "*.jpg" -o -iname "*.jpeg" \
  -o -iname "*.png" -o -iname "*.mov" -o -iname "*.mp4" \
\) -print0 | sort -z)

# ── Manifest footer ────────────────────────────────────────────────────────────
if ! $DRY_RUN; then
  cat >> "$MANIFEST" <<FOOTER

## Next Step

Ask Claude to analyze the new photos:

> "Check platform/collection/processed/ for new photos from the $DATE intake and create an inventory."

## Processed Files Location

\`platform/collection/processed/\`
FOOTER

  echo ""
  echo "  Manifest written → $MANIFEST"
fi

REMAINING=$(count_files)
echo "  Done. inbox/ has $REMAINING file(s) remaining."
echo ""
