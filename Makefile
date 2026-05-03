# NATSEC-CV — Project Makefile
# Usage: make <target>
# Run `make` or `make help` to see all targets.

REPO_ROOT        := $(shell pwd)
COLLECTION_INBOX := platform/collection/inbox
COLLECTION_PROC  := platform/collection/processed
COLLECTION_VIEW  := platform/collection/view
ATLAS_APP        := ChatGPT Atlas
LAN_HOST         := mamba.local
LAN_IP           := $(shell ipconfig getifaddr en0 2>/dev/null || echo 10.0.0.66)
ALBUM_NAME       := 810-26-NATSEC-CV
PHOTOS_LIBRARY   := /Volumes/GENAI/SUCHIR/autopsy.photoslibrary
ICLOUD_DRIVE     := $(HOME)/Library/Mobile Documents/com~apple~CloudDocs

# ── nginx / serve ──────────────────────────────────────────────────────────────
NGINX_BIN        := /usr/local/opt/nginx/bin/nginx
NGINX_CONF_DIR   := /usr/local/etc/nginx
NGINX_SUBPATH    := natsec
SERVE_PORT       := 80

.DEFAULT_GOAL := help

# ── Help ───────────────────────────────────────────────────────────────────────
.PHONY: help
help:
	@echo ""
	@echo "NATSEC-CV Makefile"
	@echo "────────────────────────────────────────────────"
	@echo "  Collection pipeline:"
	@echo "    make sync-collection     Sync photos from iCloud → inbox/"
	@echo "    make ingest-collection   Convert HEIC→JPEG, generate manifest"
	@echo "    make process-videos      Clip MOVs → H.264 MP4s + extract frames"
	@echo "    make collect             sync + ingest in one step"
	@echo ""
	@echo "  Gallery:"
	@echo "    make build-gallery       Regenerate view/index.html (images + video)"
	@echo "    make atlas               Build gallery + open in ChatGPT Atlas"
	@echo "    make open-view           Open view/ in Finder"
	@echo "    make view-url            Print file:// URL for Atlas"
	@echo ""
	@echo "  LAN server (http://$(LAN_HOST)/$(NGINX_SUBPATH)/):"
	@echo "    make serve               Build gallery + start nginx on port $(SERVE_PORT) (sudo)"
	@echo "    make serve-stop          Stop nginx"
	@echo "    make serve-reload        Reload nginx config (after gallery rebuild)"
	@echo "    make serve-status        Show nginx state + reachability URLs"
	@echo "    make serve-setup         Copy infra/nginx/ configs → nginx conf dir"
	@echo ""
	@echo "  Hotspot (natsec Wi-Fi → http://xcasa/natsec/):"
	@echo "    make hotspot-start       Create 'natsec' Wi-Fi hotspot + xcasa DNS"
	@echo "    make hotspot-stop        Tear down hotspot and dnsmasq"
	@echo "    make hotspot-status      Show hotspot state and connected clients"
	@echo ""
	@echo "  Utilities:"
	@echo "    make check               Full stack health check (hotspot+nginx+dns+gallery)"
	@echo "    make install-deps        Install osxphotos (requires pipx)"
	@echo "    make check-deps          Check required tools are present"
	@echo "    make inbox-status        Show what's waiting in inbox/"
	@echo "    make clean-inbox         Remove all files from inbox/"
	@echo "    make clean-view          Rebuild view/ from processed/"
	@echo ""

# ── Dependency check ───────────────────────────────────────────────────────────
.PHONY: check-deps
check-deps:
	@echo "Checking dependencies..."
	@command -v rsync        >/dev/null 2>&1 && echo "  ✓ rsync"     || echo "  ✗ rsync"
	@command -v sips         >/dev/null 2>&1 && echo "  ✓ sips"      || echo "  ✗ sips (macOS built-in)"
	@command -v ffmpeg       >/dev/null 2>&1 && echo "  ✓ ffmpeg"    || echo "  ✗ ffmpeg — brew install ffmpeg"
	@command -v osxphotos    >/dev/null 2>&1 && echo "  ✓ osxphotos" || echo "  ✗ osxphotos — make install-deps"
	@test -f "$(NGINX_BIN)"  && echo "  ✓ nginx"     || echo "  ✗ nginx — brew install nginx"
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
	@echo "Syncing $(ALBUM_NAME) → $(COLLECTION_INBOX)/"
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
		rsync -av --progress "$(ICLOUD_DRIVE)/$(ALBUM_NAME)/" "$(COLLECTION_INBOX)/"; \
		echo "  Sync complete."; \
	else \
		echo ""; \
		echo "  ⚠  Cannot auto-sync. Run: make install-deps"; \
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

# ── Video processing ───────────────────────────────────────────────────────────
.PHONY: process-videos
process-videos:
	@bash scripts/process-videos.sh

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

# ── Gallery ────────────────────────────────────────────────────────────────────
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

.PHONY: view-url
view-url:
	@echo ""
	@echo "file://$(REPO_ROOT)/$(COLLECTION_VIEW)/index.html"
	@echo ""

.PHONY: clean-view
clean-view:
	@echo "Rebuilding view/ from processed/ (images only)..."
	@find "$(COLLECTION_VIEW)" -maxdepth 1 -type f -delete
	@find "$(COLLECTION_PROC)" -maxdepth 1 -type f \
		\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
		-exec cp {} "$(COLLECTION_VIEW)/" \;
	@echo "  Done. view/ has $$(ls "$(COLLECTION_VIEW)" | wc -l | tr -d ' ') file(s)."
	@echo ""

# ── nginx LAN server ───────────────────────────────────────────────────────────
.PHONY: serve-setup
serve-setup:
	@echo ""
	@echo "  Setting up nginx for /$(NGINX_SUBPATH) on port $(SERVE_PORT)..."
	@test -f "$(NGINX_BIN)" || { echo "  ERROR: nginx not found. Run: brew install nginx"; exit 1; }
	@mkdir -p "$(NGINX_CONF_DIR)/servers"
	@cp infra/nginx/nginx.conf "$(NGINX_CONF_DIR)/nginx.conf"
	@cp infra/nginx/natsec.conf "$(NGINX_CONF_DIR)/servers/natsec.conf"
	@echo "  Copied nginx.conf → $(NGINX_CONF_DIR)/nginx.conf"
	@echo "  Copied natsec.conf → $(NGINX_CONF_DIR)/servers/natsec.conf"
	@$(NGINX_BIN) -t -c "$(NGINX_CONF_DIR)/nginx.conf" 2>&1 | sed 's/^/  /' && \
		echo "  Config OK." || { echo "  Config FAILED — check above."; exit 1; }
	@echo ""

.PHONY: serve
serve: build-gallery serve-setup
	@echo ""
	@echo "  NATSEC-CV Gallery — nginx LAN server"
	@echo "  ─────────────────────────────────────────────────"
	@echo "  iOS / Safari:  http://$(LAN_HOST)/$(NGINX_SUBPATH)/"
	@echo "  Android / IP:  http://$(LAN_IP)/$(NGINX_SUBPATH)/"
	@echo "  Mac (Atlas):   file://$(REPO_ROOT)/$(COLLECTION_VIEW)/index.html"
	@echo ""
	@echo "  Running on port $(SERVE_PORT) — Ctrl+C to stop"
	@echo ""
	sudo $(NGINX_BIN) -g 'daemon off;' -c "$(NGINX_CONF_DIR)/nginx.conf"

.PHONY: serve-stop
serve-stop:
	@echo "  Stopping nginx..."
	@sudo $(NGINX_BIN) -s stop 2>/dev/null && echo "  Stopped." || echo "  nginx was not running."
	@echo ""

.PHONY: serve-reload
serve-reload:
	@echo "  Reloading nginx (picking up new gallery files)..."
	@sudo $(NGINX_BIN) -s reload && echo "  Reloaded." || echo "  nginx not running — run: make serve"
	@echo ""

.PHONY: serve-status
serve-status:
	@echo ""
	@echo "  nginx status:"
	@pgrep -x nginx >/dev/null 2>&1 && echo "  ✓ Running (PID: $$(pgrep -x nginx | head -1))" || echo "  ✗ Not running"
	@echo ""
	@echo "  Config test:"
	@$(NGINX_BIN) -t -c "$(NGINX_CONF_DIR)/nginx.conf" 2>&1 | sed 's/^/    /'
	@echo ""
	@echo "  Reachable at:"
	@echo "    iOS/Safari  : http://$(LAN_HOST)/$(NGINX_SUBPATH)/"
	@echo "    Android/IP  : http://$(LAN_IP)/$(NGINX_SUBPATH)/"
	@echo "    Local test  : http://localhost/$(NGINX_SUBPATH)/"
	@echo ""
	@echo "  Logs:"
	@echo "    tail -f /usr/local/var/log/nginx/error.log"
	@echo ""

# ── Hotspot ────────────────────────────────────────────────────────────────────
HOTSPOT_SSID     := natsec
HOTSPOT_PASSWORD := natsec2026
HOTSPOT_IP       := 192.168.2.1

.PHONY: hotspot-start
hotspot-start: serve-setup
	@echo ""
	@echo "  Starting natsec hotspot (requires sudo)..."
	sudo bash scripts/setup-hotspot.sh --password "$(HOTSPOT_PASSWORD)"

.PHONY: hotspot-stop
hotspot-stop:
	@echo ""
	@echo "  Stopping natsec hotspot..."
	sudo bash scripts/setup-hotspot.sh --stop

.PHONY: hotspot-status
hotspot-status:
	@echo ""
	@echo "  Hotspot: $(HOTSPOT_SSID)"
	@BRIDGE=$$(ifconfig | awk '/^bridge/{iface=$$1} /inet 192\.168\.2\./{print iface; exit}' | tr -d ':'); \
	if [ -n "$$BRIDGE" ]; then \
		echo "  Bridge interface: $$BRIDGE ($(HOTSPOT_IP))"; \
		echo "  Status: ACTIVE"; \
	else \
		echo "  Status: not active (no 192.168.2.x bridge found)"; \
	fi
	@echo ""
	@echo "  dnsmasq (xcasa DNS):"
	@pgrep -f "dnsmasq.*natsec" >/dev/null 2>&1 && echo "  ✓ Running" || echo "  ✗ Not running"
	@echo ""
	@echo "  Access URLs (when connected to natsec):"
	@echo "    http://xcasa/natsec/         ← friendly name"
	@echo "    http://$(HOTSPOT_IP)/natsec/  ← IP fallback"
	@echo ""
	@echo "  Connected clients:"
	@arp -a | grep '192\.168\.2\.' | grep -v '\.255\b' | grep -v 'permanent' | \
		sed 's/^/    /' || echo "    none"
	@echo ""

# ── Full stack health check ────────────────────────────────────────────────────
.PHONY: check
check:
	@echo ""
	@echo "══════════════════════════════════════════"
	@echo "  NATSEC-CV Stack — Health Check"
	@echo "══════════════════════════════════════════"
	@echo ""
	@echo "── Hotspot (natsec Wi-Fi) ──────────────"
	@SSID=$$(/usr/libexec/PlistBuddy -c "Print :NAT:AirPort:NetworkName" \
	  /Library/Preferences/SystemConfiguration/com.apple.nat.plist 2>/dev/null); \
	EN=$$(/usr/libexec/PlistBuddy -c "Print :NAT:AirPort:Enabled" \
	  /Library/Preferences/SystemConfiguration/com.apple.nat.plist 2>/dev/null); \
	echo "  SSID     : $${SSID:-unknown}"; \
	echo "  Plist    : enabled=$${EN:-?}"
	@BRIDGE_IP=$$(for br in bridge100 bridge101 bridge102 bridge103; do \
	    IP=$$(ipconfig getifaddr $$br 2>/dev/null); \
	    [ -n "$$IP" ] && echo "$$IP" && break; done); \
	[ -n "$$BRIDGE_IP" ] \
	  && echo "  Bridge   : ✓ active at $$BRIDGE_IP" \
	  || echo "  Bridge   : ✗ no IP — run: make hotspot-start"
	@echo ""
	@echo "── nginx (web server) ──────────────────"
	@NPID=$$(pgrep -x nginx 2>/dev/null | head -1); \
	[ -n "$$NPID" ] \
	  && echo "  Status   : ✓ running (PID $$NPID)" \
	  || echo "  Status   : ✗ stopped — run: make serve"
	@CODE=$$(curl -so /dev/null -w "%{http_code}" --connect-timeout 2 http://localhost/natsec/ 2>/dev/null); \
	[ "$$CODE" = "200" ] \
	  && echo "  Gallery  : ✓ http://localhost/natsec/ → 200 OK" \
	  || echo "  Gallery  : ✗ http://localhost/natsec/ → $$CODE"
	@echo ""
	@echo "── dnsmasq (xcasa DNS) ─────────────────"
	@DPID=$$(cat /tmp/dnsmasq-natsec.pid 2>/dev/null); \
	if [ -n "$$DPID" ] && ps -p "$$DPID" >/dev/null 2>&1; then \
	  echo "  Status   : ✓ running (PID $$DPID)"; \
	  echo "  Resolves : xcasa → $(HOTSPOT_IP)"; \
	else \
	  echo "  Status   : ✗ stopped — run: make hotspot-start"; \
	fi
	@echo ""
	@echo "── Connected clients ───────────────────"
	@CLIENTS=$$(arp -a | grep '192\.168\.2\.' | grep -v '\.255\b' | grep -v 'permanent' | grep -v 'bridge'); \
	[ -n "$$CLIENTS" ] \
	  && echo "$$CLIENTS" | sed 's/^/  /' \
	  || echo "  None connected"
	@echo ""
	@echo "── Access URLs ─────────────────────────"
	@echo "  LAN    : http://$(LAN_HOST)/$(NGINX_SUBPATH)/"
	@echo "  LAN IP : http://$(LAN_IP)/$(NGINX_SUBPATH)/"
	@echo "  Hotspot: http://xcasa/$(NGINX_SUBPATH)/    (connect to natsec Wi-Fi first)"
	@echo "  Hotspot: http://$(HOTSPOT_IP)/$(NGINX_SUBPATH)/  (IP fallback)"
	@echo ""
	@echo "══════════════════════════════════════════"
	@echo ""

# ── Clean ──────────────────────────────────────────────────────────────────────
.PHONY: clean-inbox
clean-inbox:
	@echo "Removing all files from $(COLLECTION_INBOX)/..."
	@find "$(COLLECTION_INBOX)" -maxdepth 1 -type f -delete
	@echo "Done."
	@echo ""
