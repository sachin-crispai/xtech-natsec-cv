# NATSEC-CV — Project Makefile
# Usage: make <target>
# Run `make` or `make help` to see all targets.

REPO_ROOT       := $(shell pwd)
COLLECTION_INBOX := platform/collection/inbox
COLLECTION_PROC  := platform/collection/processed
COLLECTION_VIEW  := platform/collection/view
ATLAS_APP        := ChatGPT Atlas
ALBUM_NAME       := 810-26-NATSEC-CV
PHOTOS_LIBRARY   := /Volumes/GENAI/SUCHIR/autopsy.photoslibrary
ICLOUD_DRIVE     := $(HOME)/Library/Mobile Documents/com~apple~CloudDocs

.DEFAULT_GOAL := help

# ── Help ───────────────────────────────────────────────────────────────────────
.PHONY: help
help:
	@echo ""
	@echo "NATSEC-CV Makefile"
	@echo "────────────────────────────────────────────────"
	@echo "  make sync-collection     Sync photos from iCloud → inbox/"
	@echo "  make ingest-collection   Convert HEIC→JPEG, generate manifest"
	@echo "  make collect             sync + ingest in one step"
	@echo "  make atlas               Build grid gallery + open in Atlas"
	@echo "  make build-gallery       Regenerate view/index.html grid"
	@echo "  make open-view           Open view/ in Finder"
	@echo "  make view-url            Print file:// URL for Atlas / browser"
	@echo "  make install-deps        Install osxphotos (requires pipx)"
	@echo "  make check-deps          Check required tools are present"
	@echo "  make inbox-status        Show what's waiting in inbox/"
	@echo "  make clean-inbox         Remove all files from inbox/"
	@echo "  make clean-view          Rebuild view/ from processed/"
	@echo ""

# ── Dependency check ───────────────────────────────────────────────────────────
.PHONY: check-deps
check-deps:
	@echo "Checking dependencies..."
	@command -v rsync     >/dev/null 2>&1 && echo "  ✓ rsync"     || echo "  ✗ rsync (built-in, should always exist)"
	@command -v sips      >/dev/null 2>&1 && echo "  ✓ sips"      || echo "  ✗ sips (macOS built-in, required for HEIC conversion)"
	@command -v osxphotos >/dev/null 2>&1 && echo "  ✓ osxphotos" || echo "  ✗ osxphotos — run: make install-deps"
	@echo ""

# ── Install dependencies ───────────────────────────────────────────────────────
.PHONY: install-deps
install-deps:
	@echo "Installing osxphotos..."
	@if command -v pipx >/dev/null 2>&1; then \
		echo "  Using pipx (recommended)..."; \
		pipx install osxphotos; \
	elif command -v brew >/dev/null 2>&1; then \
		echo "  Using brew..."; \
		brew install osxphotos; \
	elif command -v pip3 >/dev/null 2>&1; then \
		echo "  Using pip3 --user..."; \
		pip3 install --user osxphotos; \
	else \
		echo "ERROR: No package manager found (tried pipx, brew, pip3)."; \
		exit 1; \
	fi
	@echo ""
	@echo "Done. Verify with: osxphotos --version"
	@echo ""

# ── Sync from iCloud ───────────────────────────────────────────────────────────
.PHONY: sync-collection
sync-collection:
	@echo ""
	@echo "Syncing APPLE-COLLECTION → $(COLLECTION_INBOX)/"
	@echo "────────────────────────────────────────────────"
	@mkdir -p "$(COLLECTION_INBOX)"

	@if command -v osxphotos >/dev/null 2>&1; then \
		echo "  Using osxphotos → album: $(ALBUM_NAME)"; \
		echo "  Library: $(PHOTOS_LIBRARY)"; \
		osxphotos export "$(COLLECTION_INBOX)" \
			--library "$(PHOTOS_LIBRARY)" \
			--album "$(ALBUM_NAME)" \
			--skip-edited \
			--no-progress \
			--overwrite \
			2>&1 | grep -v "^$$" || true; \
		echo "  Sync complete."; \
	elif [ -d "$(ICLOUD_DRIVE)/$(ALBUM_NAME)" ]; then \
		echo "  osxphotos not found — falling back to iCloud Drive rsync..."; \
		rsync -av --progress \
			"$(ICLOUD_DRIVE)/$(ALBUM_NAME)/" \
			"$(COLLECTION_INBOX)/"; \
		echo "  Sync complete."; \
	else \
		echo ""; \
		echo "  ⚠  Cannot auto-sync: osxphotos not installed and"; \
		echo "     iCloud Drive path not found."; \
		echo ""; \
		echo "  Fix option 1 (recommended):"; \
		echo "    make install-deps   # installs osxphotos"; \
		echo "    make sync-collection"; \
		echo ""; \
		echo "  Fix option 2 (manual):"; \
		echo "    Open: https://www.icloud.com/sharedalbum/#B1q5ON9t3GK4JB9"; \
		echo "    Download all photos → drop into: $(COLLECTION_INBOX)/"; \
		echo ""; \
		exit 1; \
	fi

	@echo ""
	@$(MAKE) inbox-status

# ── Ingest (convert + manifest) ────────────────────────────────────────────────
.PHONY: ingest-collection
ingest-collection:
	@echo ""
	@bash scripts/ingest-collection.sh

# ── Sync + ingest in one step ──────────────────────────────────────────────────
.PHONY: collect
collect: sync-collection ingest-collection

# ── Status ─────────────────────────────────────────────────────────────────────
.PHONY: inbox-status
inbox-status:
	@COUNT=$$(find "$(COLLECTION_INBOX)" -maxdepth 1 -type f \
		\( -iname "*.heic" -o -iname "*.jpg" -o -iname "*.jpeg" \
		   -o -iname "*.png" -o -iname "*.mov" -o -iname "*.mp4" \) \
		2>/dev/null | wc -l | tr -d ' '); \
	echo "  inbox/ contains $$COUNT file(s) ready to ingest."; \
	if [ "$$COUNT" -gt 0 ]; then \
		find "$(COLLECTION_INBOX)" -maxdepth 1 -type f \
			\( -iname "*.heic" -o -iname "*.jpg" -o -iname "*.jpeg" \
			   -o -iname "*.png" -o -iname "*.mov" -o -iname "*.mp4" \) \
			| sort | sed 's|^|    |'; \
		echo ""; \
		echo "  Run: make ingest-collection"; \
	fi
	@echo ""

# ── View (clean JPEGs only — for Atlas / browser) ──────────────────────────────
.PHONY: view-url
view-url:
	@echo ""
	@echo "file://$(REPO_ROOT)/$(COLLECTION_VIEW)/"
	@echo ""
	@echo "  $(shell ls "$(COLLECTION_VIEW)" 2>/dev/null | wc -l | tr -d ' ') files — JPEGs and PNGs only, no originals, no video."
	@echo ""

.PHONY: build-gallery
build-gallery:
	@bash scripts/build-gallery.sh

.PHONY: atlas
atlas: build-gallery
	@echo "Opening gallery in Atlas..."
	open -a "$(ATLAS_APP)" "file://$(REPO_ROOT)/$(COLLECTION_VIEW)/index.html"

.PHONY: open-view
open-view:
	open "$(COLLECTION_VIEW)"

.PHONY: clean-view
clean-view:
	@echo "Rebuilding view/ from processed/ (images only)..."
	@find "$(COLLECTION_VIEW)" -maxdepth 1 -type f -delete
	@find "$(COLLECTION_PROC)" -maxdepth 1 -type f \
		\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
		-exec cp {} "$(COLLECTION_VIEW)/" \;
	@echo "  Done. view/ has $$(ls "$(COLLECTION_VIEW)" | wc -l | tr -d ' ') file(s)."
	@echo ""

# ── Clean ──────────────────────────────────────────────────────────────────────
.PHONY: clean-inbox
clean-inbox:
	@echo "Removing all files from $(COLLECTION_INBOX)/..."
	@find "$(COLLECTION_INBOX)" -maxdepth 1 -type f -delete
	@echo "Done."
	@echo ""
