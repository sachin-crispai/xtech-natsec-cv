#!/usr/bin/env bash
# Generate platform/collection/view/index.html — image + video grid gallery
# Usage: ./scripts/build-gallery.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VIEW="$REPO_ROOT/platform/collection/view"
OUT="$VIEW/index.html"
DATE="$(date '+%Y-%m-%d %H:%M')"

# Copy pdfjs viewer into view/ (source lives in infra/pdfjs/ which is committed)
mkdir -p "$VIEW/pdfjs"
cp "$REPO_ROOT/infra/pdfjs/"* "$VIEW/pdfjs/" 2>/dev/null || true

# Copy architecture HTML into view/ so nginx serves it at /natsec/SIERRA-ARCHITECTURE.html
# The HTML uses ./mermaid.min.js — update the reference to pdfjs/mermaid.min.js
if [ -f "$REPO_ROOT/docs/architecture/SIERRA-ARCHITECTURE.html" ]; then
  sed 's|src="./mermaid.min.js"|src="pdfjs/mermaid.min.js"|g' \
    "$REPO_ROOT/docs/architecture/SIERRA-ARCHITECTURE.html" \
    > "$VIEW/SIERRA-ARCHITECTURE.html"
fi

# Collect images (bash 3.2 compatible)
IFS=$'\n' read -r -d '' -a FILES < <(find "$VIEW" -maxdepth 1 -type f \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
  | sort | xargs -I{} basename {} && printf '\0') || true

# Collect video clips
IFS=$'\n' read -r -d '' -a CLIPS < <(find "$VIEW/clips" -maxdepth 1 -type f \
  -iname "*.mp4" 2>/dev/null | sort | xargs -I{} basename {} && printf '\0') || true

COUNT="${#FILES[@]}"
CLIP_COUNT="${#CLIPS[@]}"

echo "Building gallery — $COUNT images, $CLIP_COUNT video clips → $OUT"

# ── Build image cards ──────────────────────────────────────────────────────────
IMAGE_CARDS=""
INDEX=0
for F in "${FILES[@]}"; do
  INDEX=$((INDEX + 1))
  IMAGE_CARDS+="<div class=\"card\" data-name=\"$F\" data-type=\"image\" onclick=\"toggle(this)\">"
  IMAGE_CARDS+="<img src=\"$F\" loading=\"lazy\" alt=\"$F\">"
  IMAGE_CARDS+="<div class=\"label\"><span class=\"idx\">#${INDEX}</span>$F</div>"
  IMAGE_CARDS+="</div>\n"
done

# ── Build video cards ──────────────────────────────────────────────────────────
VIDEO_CARDS=""
VIDX=0
for C in "${CLIPS[@]}"; do
  VIDX=$((VIDX + 1))
  # Derive frame preview — first frame of this clip's parent video
  PARENT=$(echo "$C" | sed 's/_clip[0-9]*.mp4//')
  THUMB="frames/${PARENT}/frame_0001.jpg"
  VIDEO_CARDS+="<div class=\"card video-card\" data-name=\"$C\" data-type=\"video\" onclick=\"toggle(this)\">"
  # Thumbnail fallback: show first frame if extracted, else video poster
  VIDEO_CARDS+="<video src=\"clips/$C\" preload=\"metadata\" muted loop"
  VIDEO_CARDS+=" onmouseenter=\"this.play()\" onmouseleave=\"this.pause();this.currentTime=0\""
  VIDEO_CARDS+=" poster=\"$THUMB\" class=\"gallery-video\"></video>"
  VIDEO_CARDS+="<div class=\"badge-video\">▶ MP4 · H.264</div>"
  VIDEO_CARDS+="<div class=\"label\"><span class=\"idx\">#${VIDX}</span>$C</div>"
  VIDEO_CARDS+="</div>\n"
done

# ── Write HTML ─────────────────────────────────────────────────────────────────
cat > "$OUT" <<HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>NATSEC-CV Collection — 810-26</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  body {
    background: #0d0d0f;
    color: #e2e2e2;
    font-family: -apple-system, "SF Pro Text", "Helvetica Neue", sans-serif;
    font-size: 13px;
  }

  /* ── Header ── */
  header {
    position: sticky; top: 0; z-index: 100;
    background: #16161a; border-bottom: 1px solid #2a2a30;
    padding: 12px 20px;
    display: flex; align-items: center; gap: 16px; flex-wrap: wrap;
  }
  header h1 { font-size: 14px; font-weight: 600; color: #fff; letter-spacing: .02em; }
  header .meta { color: #555; font-size: 12px; }
  .pill {
    background: #1e1e26; border: 1px solid #2e2e3a; border-radius: 20px;
    padding: 3px 10px; font-size: 12px; color: #aaa;
  }
  .pill span { color: #7eb8f7; font-weight: 600; }
  .pill.vid span { color: #f7a750; }
  .pill.doc span { color: #86efac; }

  /* ── Docs bar ── */
  .docs-bar {
    display: flex; gap: 10px; flex-wrap: wrap;
    padding: 10px 20px; background: #0e1a12;
    border-bottom: 1px solid #1a2e1e;
    align-items: center;
  }
  .docs-bar-label {
    font-size: 11px; font-weight: 600; text-transform: uppercase;
    letter-spacing: .08em; color: #4ade80; margin-right: 4px;
  }
  .doc-link {
    display: flex; align-items: center; gap: 7px;
    background: #0f2b19; border: 1px solid #166534;
    border-radius: 7px; padding: 6px 14px;
    color: #86efac; font-size: 12px; font-weight: 500;
    text-decoration: none; transition: background .15s, border-color .15s;
  }
  .doc-link:hover { background: #14532d; border-color: #4ade80; color: #fff; }
  .doc-link .doc-icon { font-size: 16px; line-height: 1; }
  .doc-link .doc-name { font-weight: 600; }
  .doc-link .doc-desc { color: #4ade80; font-size: 11px; }

  /* ── Toolbar ── */
  .toolbar {
    display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
    padding: 10px 20px; background: #111114; border-bottom: 1px solid #1e1e24;
  }
  button {
    background: #1e1e2a; border: 1px solid #333340; color: #ccc;
    border-radius: 6px; padding: 5px 12px; font-size: 12px;
    cursor: pointer; transition: background .15s, border-color .15s;
  }
  button:hover  { background: #25253a; border-color: #4a4a60; color: #fff; }
  button.active { background: #1a3a5c; border-color: #3a7bd5; color: #7eb8f7; }
  button.vid-active { background: #3a2010; border-color: #c07030; color: #f7a750; }
  .sep { width: 1px; height: 20px; background: #2a2a34; margin: 0 2px; }
  #sel-count { color: #7eb8f7; font-size: 12px; min-width: 80px; }
  #search {
    background: #1a1a22; border: 1px solid #2e2e3c; border-radius: 6px;
    color: #ddd; padding: 5px 10px; font-size: 12px; width: 180px; outline: none;
  }
  #search:focus { border-color: #3a7bd5; }
  .size-btns { display: flex; gap: 4px; }
  .filter-btns { display: flex; gap: 4px; }

  /* ── Section labels ── */
  .section-label {
    padding: 14px 20px 6px;
    font-size: 11px; font-weight: 600; letter-spacing: .08em;
    text-transform: uppercase; color: #444;
  }
  .section-label.vid { color: #6a4020; }

  /* ── Grid ── */
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(var(--thumb, 220px), 1fr));
    gap: 8px;
    padding: 8px 20px 20px;
  }

  /* ── Cards ── */
  .card {
    background: #16161c; border: 2px solid #222228; border-radius: 8px;
    overflow: hidden; cursor: pointer;
    transition: border-color .15s, transform .1s;
    position: relative;
  }
  .card:hover { border-color: #3a3a50; transform: translateY(-1px); }
  .card.selected { border-color: #3a7bd5; background: #0e1e34; }
  .card.selected::after {
    content: "✓"; position: absolute; top: 6px; right: 6px;
    background: #3a7bd5; color: #fff; width: 22px; height: 22px;
    border-radius: 50%; display: flex; align-items: center;
    justify-content: center; font-size: 12px; font-weight: 700;
    box-shadow: 0 1px 4px rgba(0,0,0,.5);
  }
  .card img, .card video {
    width: 100%; aspect-ratio: 4/3; object-fit: cover; display: block;
  }
  .label {
    padding: 5px 8px; font-size: 11px; color: #666;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }
  .label .idx { color: #3a3a44; margin-right: 4px; }
  .card.selected .label { color: #7eb8f7; }

  /* ── Video card extras ── */
  .video-card { border-color: #2a1e10; }
  .video-card:hover { border-color: #6a3a10; }
  .video-card.selected { border-color: #c07030; background: #201208; }
  .video-card.selected::after { background: #c07030; }
  .video-card.selected .label { color: #f7a750; }
  .badge-video {
    position: absolute; top: 6px; left: 6px;
    background: rgba(0,0,0,.7); border: 1px solid #6a3a10;
    color: #f7a750; border-radius: 4px;
    padding: 2px 7px; font-size: 10px; font-weight: 600;
    backdrop-filter: blur(4px);
  }

  /* ── Frame strip ── */
  .frame-strip-section {
    padding: 0 20px 20px;
  }
  .frame-strip-label {
    font-size: 11px; font-weight: 600; text-transform: uppercase;
    letter-spacing: .08em; color: #4a3010; padding: 14px 0 8px;
  }
  .frame-strip {
    display: flex; gap: 4px; overflow-x: auto;
    padding-bottom: 8px; scroll-snap-type: x mandatory;
  }
  .frame-strip img {
    height: 90px; width: auto; flex-shrink: 0;
    border-radius: 4px; border: 1px solid #2a1e10;
    object-fit: cover; scroll-snap-align: start;
    cursor: pointer; transition: border-color .15s, transform .1s;
  }
  .frame-strip img:hover { border-color: #c07030; transform: scale(1.04); }

  /* ── Lightbox ── */
  #lightbox {
    display: none; position: fixed; inset: 0; z-index: 200;
    background: rgba(0,0,0,.94);
    align-items: center; justify-content: center; flex-direction: column; gap: 12px;
  }
  #lightbox.open { display: flex; }
  #lightbox img, #lightbox video {
    max-width: 92vw; max-height: 85vh; object-fit: contain; border-radius: 4px;
  }
  #lightbox video { background: #000; }
  #lightbox-name { color: #666; font-size: 12px; }
  #lightbox-close {
    position: absolute; top: 16px; right: 20px;
    font-size: 28px; color: #555; cursor: pointer; line-height: 1;
  }
  #lightbox-close:hover { color: #fff; }

  /* ── Toast ── */
  #toast {
    position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%);
    background: #1a3a5c; border: 1px solid #3a7bd5; color: #7eb8f7;
    padding: 8px 18px; border-radius: 20px; font-size: 12px;
    opacity: 0; transition: opacity .3s; pointer-events: none; z-index: 300;
  }
  #toast.show { opacity: 1; }
  .hidden { display: none !important; }
</style>
</head>
<body>

<header>
  <h1>NATSEC-CV — 810-26</h1>
  <span class="meta">$DATE</span>
  <span class="pill">Images <span>$COUNT</span></span>
  <span class="pill vid">Clips <span>$CLIP_COUNT</span></span>
  <span class="pill" id="sel-count-pill">Selected <span id="sel-num">0</span></span>
</header>

<!-- ── Docs bar — architecture and reference documents ── -->
$([ -f "$VIEW/SIERRA-ARCHITECTURE.pdf" ] && echo '
<div class="docs-bar">
  <span class="docs-bar-label">Docs</span>
  <a class="doc-link" href="pdfjs/viewer.html?file=../SIERRA-ARCHITECTURE.pdf" target="_blank">
    <span class="doc-icon">&#128196;</span>
    <span>
      <span class="doc-name">SIERRA Architecture</span><br>
      <span class="doc-desc">PDF viewer · 1 / 2 / 4 page · zoom</span>
    </span>
  </a>
  <a class="doc-link" href="SIERRA-ARCHITECTURE.html" target="_blank">
    <span class="doc-icon">&#127760;</span>
    <span>
      <span class="doc-name">SIERRA Architecture</span><br>
      <span class="doc-desc">CSS diagram + glossary · HTML</span>
    </span>
  </a>
</div>' || echo '')

<div class="toolbar">
  <input id="search" type="text" placeholder="Filter filename…" oninput="filterCards()">
  <div class="filter-btns">
    <button class="active" onclick="showAll(this)">All</button>
    <button onclick="showOnly('image', this)">Images</button>
    <button onclick="showOnly('video', this)">Videos</button>
  </div>
  <div class="sep"></div>
  <button onclick="selectAll()">Select all</button>
  <button onclick="clearSel()">Clear</button>
  <button onclick="copySelected()">Copy names</button>
  <div class="sep"></div>
  <button id="mute-btn" onclick="toggleMute(this)" title="Videos start muted — click to unmute all">&#128263; Muted</button>
  <div class="sep"></div>
  <div class="size-btns">
    <button onclick="setSize(140,this)">S</button>
    <button onclick="setSize(220,this)" id="sz-m" class="active">M</button>
    <button onclick="setSize(320,this)">L</button>
    <button onclick="setSize(480,this)">XL</button>
  </div>
</div>

<!-- ── Images ── -->
<div class="section-label">Photos · $COUNT files</div>
<div class="grid" id="img-grid">
$(printf "%b" "$IMAGE_CARDS")
</div>

<!-- ── Video clips ── -->
<div class="section-label vid">Video Clips · $CLIP_COUNT × 30s · H.264 MP4 · model-ready</div>
<div class="grid" id="vid-grid">
$(printf "%b" "$VIDEO_CARDS")
</div>

<!-- ── Frame strips ── -->
$(for C in "${CLIPS[@]}"; do
  PARENT=$(echo "$C" | sed 's/_clip[0-9]*.mp4//')
  STRIP_DIR="frames/${PARENT}"
  FRAMES=$(find "$VIEW/$STRIP_DIR" -name "*.jpg" 2>/dev/null | sort | head -60)
  if [[ -n "$FRAMES" ]]; then
    echo "<div class=\"frame-strip-section\">"
    echo "  <div class=\"frame-strip-label\">$C — frame strip (1 fps)</div>"
    echo "  <div class=\"frame-strip\">"
    for FRM in $FRAMES; do
      BFM=$(basename "$FRM")
      SEC=$(echo "$BFM" | sed 's/frame_0*//' | sed 's/.jpg//')
      echo "    <img src=\"$STRIP_DIR/$BFM\" title=\"${SEC}s\" loading=\"lazy\" ondblclick=\"openLightboxImg(this.src,'$BFM')\">"
    done
    echo "  </div>"
    echo "</div>"
  fi
done)

<!-- Lightbox -->
<div id="lightbox" onclick="closeLightbox()">
  <span id="lightbox-close" onclick="closeLightbox()">×</span>
  <img id="lb-img" src="" alt="" style="display:none">
  <video id="lb-vid" controls style="display:none"></video>
  <div id="lightbox-name"></div>
</div>

<div id="toast"></div>

<script>
const allCards = () => Array.from(document.querySelectorAll('.card'));
let selected = new Set();
let activeFilter = 'all';

function toggle(el) {
  const n = el.dataset.name;
  if (selected.has(n)) { selected.delete(n); el.classList.remove('selected'); }
  else                  { selected.add(n);    el.classList.add('selected'); }
  updateCount();
}
function updateCount() {
  document.getElementById('sel-num').textContent = selected.size;
}
function selectAll() {
  allCards().forEach(c => { if (!c.classList.contains('hidden')) { selected.add(c.dataset.name); c.classList.add('selected'); }});
  updateCount();
}
function clearSel() {
  selected.clear(); allCards().forEach(c => c.classList.remove('selected')); updateCount();
}
function copySelected() {
  if (!selected.size) { toast('Nothing selected'); return; }
  navigator.clipboard.writeText([...selected].join('\n'))
    .then(() => toast(selected.size + ' name(s) copied'))
    .catch(() => toast('Copy failed'));
}
function filterCards() {
  const q = document.getElementById('search').value.toLowerCase();
  allCards().forEach(c => {
    const typeMatch = activeFilter === 'all' || c.dataset.type === activeFilter;
    const nameMatch = !q || c.dataset.name.toLowerCase().includes(q);
    c.classList.toggle('hidden', !(typeMatch && nameMatch));
  });
}
function showAll(btn) {
  activeFilter = 'all';
  setFilterBtn(btn); filterCards();
  document.getElementById('img-grid').classList.remove('hidden');
  document.getElementById('vid-grid').classList.remove('hidden');
}
function showOnly(type, btn) {
  activeFilter = type;
  setFilterBtn(btn); filterCards();
  document.getElementById('img-grid').classList.toggle('hidden', type !== 'image');
  document.getElementById('vid-grid').classList.toggle('hidden', type !== 'video');
}
function setFilterBtn(btn) {
  document.querySelectorAll('.filter-btns button').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
}
function setSize(px, btn) {
  document.querySelectorAll('.grid').forEach(g => g.style.setProperty('--thumb', px+'px'));
  document.querySelectorAll('.size-btns button').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
}

// Double-click → lightbox
allCards().forEach(c => {
  c.addEventListener('dblclick', e => {
    e.stopPropagation();
    if (c.dataset.type === 'video') {
      const src = c.querySelector('video').src;
      openLightboxVid(src, c.dataset.name);
    } else {
      const src = c.querySelector('img').src;
      openLightboxImg(src, c.dataset.name);
    }
  });
});

function openLightboxImg(src, name) {
  document.getElementById('lb-img').src = src;
  document.getElementById('lb-img').style.display = '';
  document.getElementById('lb-vid').style.display = 'none';
  document.getElementById('lb-vid').pause && document.getElementById('lb-vid').pause();
  document.getElementById('lightbox-name').textContent = name;
  document.getElementById('lightbox').classList.add('open');
}
function openLightboxVid(src, name) {
  const v = document.getElementById('lb-vid');
  v.src = src; v.style.display = '';
  v.muted = globalMuted;
  document.getElementById('lb-img').style.display = 'none';
  document.getElementById('lightbox-name').textContent = name;
  document.getElementById('lightbox').classList.add('open');
  v.play();
}
function closeLightbox() {
  document.getElementById('lightbox').classList.remove('open');
  const v = document.getElementById('lb-vid');
  v.pause && v.pause(); v.src = '';
}
document.addEventListener('keydown', e => { if (e.key === 'Escape') closeLightbox(); });

function toast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg; t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 2200);
}

// ── Mute / unmute all videos ───────────────────────────────────────────────
let globalMuted = true;

function toggleMute(btn) {
  globalMuted = !globalMuted;
  document.querySelectorAll('video.gallery-video').forEach(v => { v.muted = globalMuted; });
  document.getElementById('lb-vid').muted = globalMuted;
  btn.innerHTML = globalMuted ? '&#128263; Muted' : '&#128266; Unmuted';
  btn.classList.toggle('active', !globalMuted);
  toast(globalMuted ? 'Videos muted' : 'Videos unmuted — hover a clip to hear audio');
}
</script>
</body>
</html>
HTMLEOF

echo "  Done → $OUT"
