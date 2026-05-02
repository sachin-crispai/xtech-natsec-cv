# NATSEC-CV — Project Makefile
# Usage: make <target>
# Run `make` or `make help` to see all targets.

REPO_ROOT       := $(shell pwd)
COLLECTION_INBOX := platform/collection/inbox
COLLECTION_PROC  := platform/collection/processed
ALBUM_NAME       := APPLE-COLLECTION
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
	@echo "  make install-deps        Install osxphotos (requires pip3)"
	@echo "  make check-deps          Check required tools are present"
	@echo "  make inbox-status        Show what's waiting in inbox/"
	@echo "  make clean-inbox         Remove all files from inbox/"
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
	@command -v pip3 >/dev/null 2>&1 || (echo "ERROR: pip3 not found. Install Python 3 first." && exit 1)
	pip3 install osxphotos
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
		echo "  Using osxphotos (Photos app / iCloud shared album)..."; \
		osxphotos export "$(COLLECTION_INBOX)" \
			--album "$(ALBUM_NAME)" \
			--skip-edited-suffix \
			--original \
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

# ── Clean ──────────────────────────────────────────────────────────────────────
.PHONY: clean-inbox
clean-inbox:
	@echo "Removing all files from $(COLLECTION_INBOX)/..."
	@find "$(COLLECTION_INBOX)" -maxdepth 1 -type f -delete
	@echo "Done."
	@echo ""
