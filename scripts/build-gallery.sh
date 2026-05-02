#!/usr/bin/env bash
# Generate platform/collection/view/index.html — image grid gallery
# Usage: ./scripts/build-gallery.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VIEW="$REPO_ROOT/platform/collection/view"
OUT="$VIEW/index.html"
DATE="$(date '+%Y-%m-%d %H:%M')"

# Collect all image files sorted (bash 3.2 compatible)
IFS=$'\n' read -r -d '' -a FILES < <(find "$VIEW" -maxdepth 1 -type f \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
  | sort | xargs -I{} basename {} && printf '\0') || true

COUNT="${#FILES[@]}"

echo "Building gallery — $COUNT images → $OUT"

# ── Build image rows ────────────────────────────────────────────────────────────
CARDS=""
INDEX=0
for F in "${FILES[@]}"; do
  INDEX=$((INDEX + 1))
  CARDS+="    <div class=\"card\" data-name=\"$F\" onclick=\"toggle(this)\">"
  CARDS+="<img src=\"$F\" loading=\"lazy\" alt=\"$F\">"
  CARDS+="<div class=\"label\"><span class=\"idx\">#$INDEX</span> $F</div>"
  CARDS+="</div>\n"
done

# ── Write HTML ─────────────────────────────────────────────────────────────────
cat > "$OUT" <<HTML
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
    background: #16161a;
    border-bottom: 1px solid #2a2a30;
    padding: 12px 20px;
    display: flex; align-items: center; gap: 16px; flex-wrap: wrap;
  }
  header h1 { font-size: 14px; font-weight: 600; color: #fff; letter-spacing: .02em; }
  header .meta { color: #666; font-size: 12px; }
  .pill {
    background: #1e1e26; border: 1px solid #2e2e3a; border-radius: 20px;
    padding: 3px 10px; font-size: 12px; color: #aaa;
  }
  .pill span { color: #7eb8f7; font-weight: 600; }

  /* ── Toolbar ── */
  .toolbar {
    display: flex; align-items: center; gap: 10px; flex-wrap: wrap;
    padding: 10px 20px;
    background: #111114;
    border-bottom: 1px solid #1e1e24;
  }
  button {
    background: #1e1e2a; border: 1px solid #333340; color: #ccc;
    border-radius: 6px; padding: 5px 12px; font-size: 12px;
    cursor: pointer; transition: background .15s, border-color .15s;
  }
  button:hover { background: #25253a; border-color: #4a4a60; color: #fff; }
  button.active { background: #1a3a5c; border-color: #3a7bd5; color: #7eb8f7; }
  #sel-count { color: #7eb8f7; font-size: 12px; min-width: 80px; }
  #search {
    background: #1a1a22; border: 1px solid #2e2e3c; border-radius: 6px;
    color: #ddd; padding: 5px 10px; font-size: 12px; width: 200px;
    outline: none;
  }
  #search:focus { border-color: #3a7bd5; }
  .size-btns { display: flex; gap: 4px; }

  /* ── Grid ── */
  #grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(var(--thumb, 220px), 1fr));
    gap: 8px;
    padding: 16px 20px;
  }

  .card {
    background: #16161c;
    border: 2px solid #222228;
    border-radius: 8px;
    overflow: hidden;
    cursor: pointer;
    transition: border-color .15s, transform .1s;
    position: relative;
  }
  .card:hover { border-color: #3a3a50; transform: translateY(-1px); }
  .card.selected { border-color: #3a7bd5; background: #0e1e34; }
  .card.selected::after {
    content: "✓";
    position: absolute; top: 6px; right: 6px;
    background: #3a7bd5; color: #fff;
    width: 22px; height: 22px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-size: 12px; font-weight: 700;
    box-shadow: 0 1px 4px rgba(0,0,0,.5);
  }
  .card img {
    width: 100%; aspect-ratio: 4/3; object-fit: cover; display: block;
  }
  .label {
    padding: 5px 8px; font-size: 11px; color: #777;
    white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
  }
  .label .idx { color: #444; margin-right: 4px; }
  .card.selected .label { color: #7eb8f7; }
  .card.hidden { display: none; }

  /* ── Lightbox ── */
  #lightbox {
    display: none; position: fixed; inset: 0; z-index: 200;
    background: rgba(0,0,0,.92); align-items: center; justify-content: center;
    flex-direction: column; gap: 12px;
  }
  #lightbox.open { display: flex; }
  #lightbox img { max-width: 92vw; max-height: 85vh; object-fit: contain; border-radius: 4px; }
  #lightbox-name { color: #888; font-size: 12px; }
  #lightbox-close {
    position: absolute; top: 16px; right: 20px;
    font-size: 28px; color: #666; cursor: pointer; line-height: 1;
  }
  #lightbox-close:hover { color: #fff; }

  /* ── Toast ── */
  #toast {
    position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%);
    background: #1a3a5c; border: 1px solid #3a7bd5; color: #7eb8f7;
    padding: 8px 18px; border-radius: 20px; font-size: 12px;
    opacity: 0; transition: opacity .3s; pointer-events: none;
  }
  #toast.show { opacity: 1; }
</style>
</head>
<body>

<header>
  <h1>NATSEC-CV Collection — 810-26</h1>
  <span class="meta">Generated $DATE</span>
  <span class="pill">Total <span>$COUNT</span></span>
  <span class="pill" id="vis-count">Visible <span id="vis-num">$COUNT</span></span>
</header>

<div class="toolbar">
  <input id="search" type="text" placeholder="Filter by filename…" oninput="filterCards()">
  <span id="sel-count">0 selected</span>
  <button onclick="selectAll()">Select all</button>
  <button onclick="clearSelection()">Clear</button>
  <button onclick="copySelected()">Copy names</button>
  <div class="size-btns">
    <button onclick="setSize(140)" title="Small">S</button>
    <button onclick="setSize(220)" title="Medium" class="active" id="sz-m">M</button>
    <button onclick="setSize(320)" title="Large">L</button>
    <button onclick="setSize(480)" title="XL">XL</button>
  </div>
</div>

<div id="grid">
$(printf "%b" "$CARDS")
</div>

<!-- Lightbox -->
<div id="lightbox" onclick="closeLightbox()">
  <span id="lightbox-close" onclick="closeLightbox()">×</span>
  <img id="lb-img" src="" alt="">
  <div id="lightbox-name"></div>
</div>

<div id="toast"></div>

<script>
const grid = document.getElementById('grid');
const cards = Array.from(grid.querySelectorAll('.card'));
let selected = new Set();

function toggle(el) {
  const name = el.dataset.name;
  if (selected.has(name)) { selected.delete(name); el.classList.remove('selected'); }
  else                     { selected.add(name);    el.classList.add('selected'); }
  updateCount();
}

function updateCount() {
  document.getElementById('sel-count').textContent = selected.size + ' selected';
}

function selectAll() {
  cards.forEach(c => { if (!c.classList.contains('hidden')) { selected.add(c.dataset.name); c.classList.add('selected'); }});
  updateCount();
}

function clearSelection() {
  selected.clear();
  cards.forEach(c => c.classList.remove('selected'));
  updateCount();
}

function copySelected() {
  if (!selected.size) { toast('Nothing selected'); return; }
  navigator.clipboard.writeText([...selected].join('\n'))
    .then(() => toast(selected.size + ' filename(s) copied'))
    .catch(() => toast('Copy failed — try another browser'));
}

function filterCards() {
  const q = document.getElementById('search').value.toLowerCase();
  let vis = 0;
  cards.forEach(c => {
    const match = !q || c.dataset.name.toLowerCase().includes(q);
    c.classList.toggle('hidden', !match);
    if (match) vis++;
  });
  document.getElementById('vis-num').textContent = vis;
}

function setSize(px) {
  document.getElementById('grid').style.setProperty('--thumb', px + 'px');
  document.querySelectorAll('.size-btns button').forEach(b => b.classList.remove('active'));
  event.target.classList.add('active');
}

// Double-click → lightbox
cards.forEach(c => {
  c.addEventListener('dblclick', e => {
    e.stopPropagation();
    const img = c.querySelector('img');
    document.getElementById('lb-img').src = img.src;
    document.getElementById('lightbox-name').textContent = c.dataset.name;
    document.getElementById('lightbox').classList.add('open');
  });
});

function closeLightbox() { document.getElementById('lightbox').classList.remove('open'); }
document.addEventListener('keydown', e => { if (e.key === 'Escape') closeLightbox(); });

function toast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg; t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 2200);
}
</script>
</body>
</html>
HTML

echo "  Done → $OUT"
echo "  open -a \"ChatGPT Atlas\" \"file://$OUT\""
