#!/usr/bin/env bash
# Open Atlas in split view: gallery on left, iCloud album on right
# Usage: bash scripts/split-view.sh
#        make split-view

GALLERY_URL="file:///Volumes/WORK900_CRISPAI/810-26-NATSEC-CV/platform/collection/view/index.html"
ALBUM_URL="https://www.icloud.com/sharedalbum/#B1q5ON9t3GK4JB9"
ATLAS_APP="ChatGPT Atlas"

osascript << ASEOF
-- ── Get screen dimensions ──────────────────────────────────────────────────
tell application "Finder"
    set screenBounds to bounds of window of desktop
    set sw to item 3 of screenBounds
    set sh to item 4 of screenBounds
end tell

set halfW to (sw / 2) as integer
set menuH to 38   -- macOS menu bar height

-- ── Open gallery window ────────────────────────────────────────────────────
tell application "$ATLAS_APP"
    activate
    open location "$GALLERY_URL"
end tell
delay 1.5

-- ── Open album window ─────────────────────────────────────────────────────
tell application "$ATLAS_APP"
    open location "$ALBUM_URL"
end tell
delay 1.5

-- ── Tile or stack depending on window count ──────────────────────────────
tell application "System Events"
    tell process "$ATLAS_APP"
        set allWins to every window
        set winCount to count allWins

        if winCount >= 2 then
            -- Split view: gallery left, album right
            set position of item 2 of allWins to {0, menuH}
            set size     of item 2 of allWins to {halfW, sh - menuH}
            set position of item 1 of allWins to {halfW, menuH}
            set size     of item 1 of allWins to {halfW, sh - menuH}
            return "split"
        else
            -- Single window: maximise it, both URLs are tabs stacked below each other
            set position of item 1 of allWins to {0, menuH}
            set size     of item 1 of allWins to {sw, sh - menuH}
            return "stacked"
        end if
    end tell
end tell
ASEOF

# Check which mode was used and report
RESULT=$(osascript -e '
tell application "System Events"
    tell process "ChatGPT Atlas"
        return count of every window
    end tell
end tell' 2>/dev/null)

if [ "${RESULT:-0}" -ge 2 ] 2>/dev/null; then
    echo "  Split view:  gallery (left) | iCloud album (right)"
else
    echo "  Single window: both URLs open as tabs (gallery + album)"
    echo "  Use Cmd+[ / Cmd+] to switch between tabs"
fi
