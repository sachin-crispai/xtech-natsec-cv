#!/usr/bin/env bash
# Process videos from platform/collection/processed/ into model-ready clips + frames
#
# Output:
#   platform/collection/view/clips/   — short MP4 H.264 clips (30s default)
#   platform/collection/view/frames/  — JPEG frames at 1fps per video
#
# Usage:
#   ./scripts/process-videos.sh [--clip-duration 30] [--fps 1] [--dry-run]
#
# Best format choices:
#   Container:  MP4       — widest model support (Gemini, GPT-4V, Claude)
#   Codec:      H.264     — hardware-decoded everywhere, preferred over HEVC for APIs
#   Resolution: 720p max  — sufficient for frame analysis, keeps file small
#   Bitrate:    1200 kbps — ~4.3 MB/30s clip; good quality for visual analysis
#   Audio:      stripped  — not needed for hardware/CV analysis
#   Frames:     1 fps     — enough for static hardware surveys; raise for motion

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROCESSED="$REPO_ROOT/platform/collection/processed"
CLIPS_DIR="$REPO_ROOT/platform/collection/view/clips"
FRAMES_DIR="$REPO_ROOT/platform/collection/view/frames"

CLIP_DURATION=30
FRAME_FPS=1
DRY_RUN=false

# ── Arg parsing ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --clip-duration) CLIP_DURATION="$2"; shift 2 ;;
    --fps)           FRAME_FPS="$2";     shift 2 ;;
    --dry-run)       DRY_RUN=true;       shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

log()  { echo "  $*"; }

mkdir -p "$CLIPS_DIR" "$FRAMES_DIR"

# Find all videos in processed/
VIDEOS=$(find "$PROCESSED" -maxdepth 1 -type f \
  \( -iname "*.mov" -o -iname "*.mp4" -o -iname "*.avi" \) | sort)

if [[ -z "$VIDEOS" ]]; then
  echo "  No videos found in processed/ — nothing to do."
  exit 0
fi

echo ""
echo "NATSEC-CV Video Processor"
echo "────────────────────────────────────"
echo "  Clip duration : ${CLIP_DURATION}s"
echo "  Frame rate    : ${FRAME_FPS} fps"
echo "  Output clips  : $CLIPS_DIR"
echo "  Output frames : $FRAMES_DIR"
$DRY_RUN && echo "  [DRY RUN]"
echo ""

TOTAL_CLIPS=0
TOTAL_FRAMES=0

while IFS= read -r VIDEO; do
  [[ -z "$VIDEO" ]] && continue
  BASENAME="$(basename "$VIDEO")"
  NAME="${BASENAME%.*}"

  # Get duration
  DURATION=$(ffprobe -v quiet -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$VIDEO" 2>/dev/null | cut -d. -f1)
  DURATION=${DURATION:-0}

  # Get resolution
  RESOLUTION=$(ffprobe -v quiet -select_streams v:0 \
    -show_entries stream=width,height \
    -of csv=p=0 "$VIDEO" 2>/dev/null | head -1)
  WIDTH=$(echo "$RESOLUTION" | cut -d, -f1)
  HEIGHT=$(echo "$RESOLUTION" | cut -d, -f2)

  log "[$BASENAME] ${DURATION}s — ${WIDTH}x${HEIGHT}"

  # ── Cap resolution at 720p ────────────────────────────────────────────────
  SCALE_FILTER=""
  if [[ -n "$HEIGHT" && "$HEIGHT" -gt 720 ]]; then
    SCALE_FILTER="-vf scale=-2:720"
    log "  → scaling down to 720p"
  fi

  # ── Clip into segments ────────────────────────────────────────────────────
  START=0
  SEG=1
  while [[ $START -lt $DURATION ]]; do
    PADDED=$(printf "%03d" $SEG)
    CLIP_NAME="${NAME}_clip${PADDED}.mp4"
    CLIP_OUT="$CLIPS_DIR/$CLIP_NAME"

    log "  clip $SEG: ${START}s → $((START + CLIP_DURATION))s → $CLIP_NAME"
    if ! $DRY_RUN; then
      ffmpeg -y -v quiet \
        -ss "$START" -i "$VIDEO" \
        -t "$CLIP_DURATION" \
        $SCALE_FILTER \
        -c:v libx264 -preset fast -crf 23 \
        -b:v 1200k -maxrate 1500k -bufsize 3000k \
        -an \
        -movflags +faststart \
        "$CLIP_OUT" 2>/dev/null
      SIZE=$(du -sh "$CLIP_OUT" | cut -f1)
      log "    → $SIZE"
    fi

    START=$((START + CLIP_DURATION))
    SEG=$((SEG + 1))
    TOTAL_CLIPS=$((TOTAL_CLIPS + 1))
  done

  # ── Extract frames at N fps ───────────────────────────────────────────────
  FRAME_OUT_DIR="$FRAMES_DIR/${NAME}"
  mkdir -p "$FRAME_OUT_DIR"
  log "  frames: extracting at ${FRAME_FPS}fps → $FRAME_OUT_DIR/"
  if ! $DRY_RUN; then
    ffmpeg -y -v quiet \
      -i "$VIDEO" \
      $SCALE_FILTER \
      -vf "fps=${FRAME_FPS}" \
      -q:v 2 \
      "$FRAME_OUT_DIR/frame_%04d.jpg" 2>/dev/null
    NFRAMES=$(find "$FRAME_OUT_DIR" -name "*.jpg" | wc -l | tr -d ' ')
    TOTAL_FRAMES=$((TOTAL_FRAMES + NFRAMES))
    log "  → $NFRAMES frames extracted"
  fi

  echo ""

done <<< "$VIDEOS"

echo "  Done."
echo "  Total clips  : $TOTAL_CLIPS"
echo "  Total frames : $TOTAL_FRAMES"
echo ""
echo "  Clips  : file://$CLIPS_DIR/"
echo "  Frames : file://$FRAMES_DIR/"
echo ""
