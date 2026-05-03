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
ICLOUD_URL       := https://www.icloud.com/sharedalbum/\#B1q5ON9t3GK4JB9
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
	@echo "    make photo-status        Count photos at every pipeline stage + gap analysis"
	@echo "    make sync-from-link      Sync from public iCloud shared album URL"
	@echo "    make sync-collection     Sync NEW photos only from local Photos app"
	@echo "    make sync-collection-full  Force re-sync ALL photos from Photos app"
	@echo "    make ingest-collection   Convert HEIC→JPEG, generate manifest"
	@echo "    make process-videos      Clip MOVs → H.264 MP4s + extract frames"
	@echo "    make collect             sync (incremental) + ingest in one step"
	@echo ""
	@echo "  Gallery:"
	@echo "    make build-gallery       Regenerate view/index.html (images + video)"
	@echo "    make atlas               Build gallery + open in ChatGPT Atlas"
	@echo "    make open-view           Open view/ in Finder"
	@echo "    make view-url            Print file:// URL for Atlas"
	@echo ""
	@echo "  LAN server (http://$(LAN_HOST)/$(NGINX_SUBPATH)/):"
	@echo "    make serve               Build gallery + start nginx in background (sudo)"
	@echo "    make serve-stop          Stop nginx"
	@echo "    make serve-reload        Reload nginx after gallery rebuild"
	@echo "    make serve-logs          Tail nginx access + error logs"
	@echo "    make serve-status        Show nginx state + reachability URLs"
	@echo "    make serve-setup         Copy infra/nginx/ configs → nginx conf dir"
	@echo ""
	@echo "  Quick start / stop (customer site):"
	@echo "    make up                  Plug in Ethernet, run this — everything starts"
	@echo "    make down                Tear everything down cleanly"
	@echo "    make speedtest           Network diagnostics + gallery serve benchmarks"
	@echo ""
	@echo "  Hotspot (natsec Wi-Fi → http://xcasa/natsec/):"
	@echo "    make hotspot-start       Create 'natsec' Wi-Fi hotspot + xcasa DNS"
	@echo "    make hotspot-stop        Tear down hotspot and dnsmasq"
	@echo "    make hotspot-status      Show hotspot state and connected clients"
	@echo ""
	@echo "  Diagnostics / recovery:"
	@echo "    make doctor              Deep hotspot + stack diagnosis with exact fixes"
	@echo "    make check               Quick health check (all layers)"
	@echo "    make speedtest           Network speed + gallery benchmarks"
	@echo "    make fix-routes          Fix broken IPv4 routing after hotspot start"
	@echo "    make show-notes          Known issues, gotchas, and field fixes"
	@echo "    make enable-touchid      Use Touch ID fingerprint for all sudo commands"
	@echo "    make disable-touchid     Revert to password for sudo"
	@echo ""
	@echo "  Utilities:"
	@echo "    make check-deps          Check required tools are installed"
	@echo "    make install-deps        Install osxphotos"
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
	@command -v ffmpeg        >/dev/null 2>&1 && echo "  ✓ ffmpeg"        || echo "  ✗ ffmpeg — brew install ffmpeg"
	@command -v osxphotos     >/dev/null 2>&1 && echo "  ✓ osxphotos"     || echo "  ✗ osxphotos — make install-deps"
	@test -f "$(NGINX_BIN)"   && echo "  ✓ nginx"         || echo "  ✗ nginx — brew install nginx"
	@command -v speedtest-cli >/dev/null 2>&1 && echo "  ✓ speedtest-cli" || echo "  ✗ speedtest-cli — brew install speedtest-cli"
	@command -v iperf3        >/dev/null 2>&1 && echo "  ✓ iperf3"        || echo "  ✗ iperf3 — brew install iperf3"
	@command -v dnsmasq       >/dev/null 2>&1 && echo "  ✓ dnsmasq"       || echo "  ✗ dnsmasq — brew install dnsmasq"
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

# ── Photo status ───────────────────────────────────────────────────────────────
# Pass PHONE=91 to compare against your phone count, e.g: make photo-status PHONE=91
PHONE ?= unknown
.PHONY: photo-status
photo-status:
	@bash scripts/photo-status.sh "$(PHONE)"

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
			--update --only-new \
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

# ── Sync from iCloud shared link (no Photos app needed) ───────────────────────
.PHONY: sync-from-link
sync-from-link:
	@bash scripts/sync-icloud-link.sh "$(ICLOUD_URL)"

# ── Full re-sync (all photos, overwrites) ─────────────────────────────────────
.PHONY: sync-collection-full
sync-collection-full:
	@echo ""
	@echo "Force re-syncing ALL photos from $(ALBUM_NAME)..."
	@mkdir -p "$(COLLECTION_INBOX)"
	@osxphotos export "$(COLLECTION_INBOX)" \
		--library "$(PHOTOS_LIBRARY)" \
		--album "$(ALBUM_NAME)" \
		--skip-edited \
		--no-progress \
		--overwrite \
		2>&1 | grep -v "^$$" || true
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
	@sudo $(NGINX_BIN) -s stop -c "$(NGINX_CONF_DIR)/nginx.conf" 2>/dev/null || true
	@sudo $(NGINX_BIN) -c "$(NGINX_CONF_DIR)/nginx.conf"
	@echo "  NATSEC-CV Gallery — nginx running in background"
	@echo "  ─────────────────────────────────────────────────"
	@echo "  iOS / Safari:  http://$(LAN_HOST)/$(NGINX_SUBPATH)/"
	@echo "  Android / IP:  http://$(LAN_IP)/$(NGINX_SUBPATH)/"
	@echo "  Hotspot:       http://xcasa/$(NGINX_SUBPATH)/"
	@echo "  Mac (Atlas):   file://$(REPO_ROOT)/$(COLLECTION_VIEW)/index.html"
	@echo ""
	@echo "  make serve-stop    — stop nginx"
	@echo "  make serve-logs    — tail access + error logs"
	@echo "  make check         — full stack health check"
	@echo ""

.PHONY: serve-logs
serve-logs:
	@echo "  Tailing nginx logs (Ctrl+C to stop)..."
	@echo ""
	tail -f /usr/local/var/log/nginx/access.log /usr/local/var/log/nginx/error.log

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


# ── Quick start / stop ─────────────────────────────────────────────────────────
.PHONY: up
up:
	@echo ""
	@echo "  ┌─────────────────────────────────────────┐"
	@echo "  │  NATSEC-CV  —  Starting full stack      │"
	@echo "  └─────────────────────────────────────────┘"
	@echo ""
	@$(MAKE) build-gallery
	@$(MAKE) hotspot-start
	@$(MAKE) serve
	@echo ""
	@$(MAKE) check
	@echo "  ┌─────────────────────────────────────────┐"
	@echo "  │  Ready. Share these with your team:     │"
	@echo "  │  Wi-Fi   : natsec                       │"
	@echo "  │  Password: $(HOTSPOT_PASSWORD)           │"
	@echo "  │  URL     : http://xcasa/natsec/         │"
	@echo "  └─────────────────────────────────────────┘"
	@echo ""

.PHONY: down
down:
	@echo ""
	@echo "  Shutting down NATSEC-CV stack..."
	@$(MAKE) serve-stop       2>/dev/null || true
	@$(MAKE) hotspot-stop     2>/dev/null || true
	@echo "  Done."
	@echo ""

# ── Speed test ─────────────────────────────────────────────────────────────────
.PHONY: speedtest
speedtest:
	@echo ""
	@echo "══════════════════════════════════════════════════"
	@echo "  NATSEC-CV Network Diagnostics — $$(date '+%Y-%m-%d %H:%M')"
	@echo "══════════════════════════════════════════════════"
	@echo ""
	@echo "── Ethernet Link ────────────────────────────────"
	@ETH=$$(networksetup -listallhardwareports 2>/dev/null \
	  | awk '/Hardware Port:.*[Ee]thernet/{found=1} found && /Device:/{print $$2; found=0}' \
	  | while read dev; do \
	      link=$$(ifconfig "$$dev" 2>/dev/null | grep -o 'status: [a-z]*' | awk '{print $$2}'); \
	      ip=$$(ipconfig getifaddr "$$dev" 2>/dev/null); \
	      [ "$$link" = "active" ] && [ -n "$$ip" ] && echo "$$dev $$ip" && break; \
	  done); \
	if [ -n "$$ETH" ]; then \
	  DEV=$$(echo $$ETH | awk '{print $$1}'); \
	  IP=$$(echo $$ETH | awk '{print $$2}'); \
	  MEDIA=$$(ifconfig $$DEV | grep media | awk '{print $$2, $$3}'); \
	  echo "  Interface : $$DEV ($$IP)"; \
	  echo "  Link      : $$MEDIA"; \
	else \
	  echo "  ✗ No active Ethernet — plug in cable first"; \
	fi
	@echo ""
	@echo "── Latency ──────────────────────────────────────"
	@GW=$$(netstat -rn | awk '/default/{print $$2; exit}'); \
	echo "  Gateway ($$GW):"; \
	ping -c 4 -i 0.2 $$GW 2>/dev/null | tail -1 | sed 's/^/    /'; \
	echo "  Cloudflare 1.1.1.1:"; \
	ping -c 4 -i 0.2 1.1.1.1 2>/dev/null | tail -1 | sed 's/^/    /'
	@echo ""
	@echo "── Internet Speed ───────────────────────────────"
	@command -v speedtest-cli >/dev/null 2>&1 \
	  && speedtest-cli --simple 2>/dev/null | sed 's/^/  /' \
	  || echo "  speedtest-cli not installed — run: brew install speedtest-cli"
	@echo ""
	@echo "── Gallery Serve Speed (nginx local) ────────────"
	@if pgrep -x nginx >/dev/null 2>&1; then \
	  printf "  %-14s" "index.html:"; \
	  curl -so /dev/null \
	    -w "%{time_total}s   %{size_download} bytes   %{speed_download} B/s\n" \
	    http://localhost/$(NGINX_SUBPATH)/ 2>/dev/null; \
	  printf "  %-14s" "photo (JPEG):"; \
	  curl -so /dev/null \
	    -w "%{time_total}s   %{size_download} bytes   %{speed_download} B/s\n" \
	    http://localhost/$(NGINX_SUBPATH)/IMG_0060.jpg 2>/dev/null; \
	  printf "  %-14s" "video clip:"; \
	  curl -so /dev/null \
	    -w "%{time_total}s   %{size_download} bytes   %{speed_download} B/s\n" \
	    http://localhost/$(NGINX_SUBPATH)/clips/IMG_0072_clip001.mp4 2>/dev/null; \
	else \
	  echo "  nginx not running — start with: make serve"; \
	fi
	@echo ""
	@echo "── Estimated Client Experience on natsec ────────"
	@echo "  78 KB  index.html  → <0.1s  on any Wi-Fi"
	@echo "  2-3 MB photo JPEG  → ~0.3s  on 100 Mbps hotspot"
	@echo "  5-6 MB video clip  → ~0.5s  on 100 Mbps hotspot"
	@echo "══════════════════════════════════════════════════"
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

# ── Doctor ─────────────────────────────────────────────────────────────────────
# Deep diagnostic for hotspot + full stack. Checks each known failure mode,
# prints PASS/FAIL, and for every failure prints the exact fix command.
# Safe to run at any time — read-only, no changes made.
.PHONY: doctor
doctor:
	@bash scripts/doctor.sh

# ── Touch ID for sudo ──────────────────────────────────────────────────────────
#
# How it works (macOS Sequoia):
#   /etc/pam.d/sudo already includes sudo_local (line 1).
#   sudo_local.template has the Touch ID line commented out.
#   Creating /etc/pam.d/sudo_local with pam_tid.so uncommented enables Touch ID.
#   'sufficient' = Touch ID works → done. Touch ID fails / external keyboard → falls
#   back to password automatically. Safe to use everywhere.
#   sudo_local survives macOS system updates (unlike editing /etc/pam.d/sudo directly).
#
PAM_SUDO_LOCAL := /etc/pam.d/sudo_local

.PHONY: enable-touchid
enable-touchid:
	@echo ""
	@if [ -f "$(PAM_SUDO_LOCAL)" ] && grep -q "^auth.*pam_tid" "$(PAM_SUDO_LOCAL)" 2>/dev/null; then \
	  echo "  ✓ Touch ID for sudo already enabled — no change needed."; \
	  echo "  $(PAM_SUDO_LOCAL):"; \
	  cat "$(PAM_SUDO_LOCAL)" | sed 's/^/    /'; \
	else \
	  echo "  Writing $(PAM_SUDO_LOCAL) (requires sudo — touch the sensor or enter password):"; \
	  echo ""; \
	  sudo bash -c "printf '# sudo_local: survives macOS updates\nauth       sufficient     pam_tid.so\n' \
	    > $(PAM_SUDO_LOCAL)"; \
	  if grep -q "pam_tid" "$(PAM_SUDO_LOCAL)" 2>/dev/null; then \
	    echo "  ✓ Touch ID enabled for sudo."; \
	    echo "  File contents:"; \
	    cat "$(PAM_SUDO_LOCAL)" | sed 's/^/    /'; \
	    echo ""; \
	    echo "  All future sudo prompts will use Touch ID."; \
	    echo "  Falls back to password automatically on external keyboards."; \
	  else \
	    echo "  ✗ Failed — file not created. Run manually:"; \
	    echo "    sudo bash -c \"printf 'auth sufficient pam_tid.so\\\n' > /etc/pam.d/sudo_local\""; \
	  fi; \
	fi
	@echo ""

.PHONY: disable-touchid
disable-touchid:
	@echo ""
	@if [ ! -f "$(PAM_SUDO_LOCAL)" ]; then \
	  echo "  Touch ID for sudo is not enabled — nothing to do."; \
	else \
	  sudo rm -f "$(PAM_SUDO_LOCAL)"; \
	  echo "  ✓ Touch ID disabled. sudo will prompt for password again."; \
	fi
	@echo ""

# ── Route fix ──────────────────────────────────────────────────────────────────
#
# KNOWN ISSUE: macOS Internet Sharing rewrites the IPv4 routing table when it
# starts. It injects bridge interfaces (bridge100-103) as default routes with
# the reject flag (!), which replaces the real gateway (10.0.0.1 via en9) and
# kills internet connectivity on the Mac.
#
# SAFE FIX: renew DHCP on the Ethernet interface only. This re-requests the
# gateway from the router without touching any other routes. It is safe to run
# at any time and is idempotent.
#
# UNSAFE ALTERNATIVE (do NOT automate): `sudo route flush` — this removes ALL
# routes including loopback and link-local, causing a brief full network outage
# while macOS rebuilds them. Only use manually if DHCP renewal fails.
#
.PHONY: fix-routes
fix-routes:
	@echo ""
	@echo "  Checking IPv4 routing..."
	@INET=$$(ping -c 1 -t 2 8.8.8.8 2>/dev/null | grep -c "1 received" || echo 0); \
	if [ "$$INET" = "1" ]; then \
	  echo "  ✓ Internet is reachable — no fix needed."; \
	else \
	  echo "  ✗ No internet. Renewing DHCP on Ethernet (en9)..."; \
	  echo "    (This is safe — only renews the Ethernet lease, touches nothing else)"; \
	  sudo ipconfig set en9 DHCP; \
	  sleep 3; \
	  GW=$$(netstat -rn -f inet 2>/dev/null | awk '/default.*en9/{print $$2; exit}'); \
	  if [ -n "$$GW" ]; then \
	    echo "  ✓ Route restored — gateway: $$GW via en9"; \
	  else \
	    echo "  ✗ DHCP renewal did not restore route. Manual fix:"; \
	    echo "    sudo route delete default"; \
	    echo "    sudo route add default 10.0.0.1"; \
	  fi; \
	fi
	@echo ""

# ── Field notes ────────────────────────────────────────────────────────────────
#
# This target is a field reference — run it at a customer site to recall known
# issues and their fixes without needing internet access or documentation.
#
.PHONY: show-notes
show-notes:
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════════╗"
	@echo "║  NATSEC-CV Field Notes — Known Issues & Fixes                   ║"
	@echo "╠══════════════════════════════════════════════════════════════════╣"
	@echo "║                                                                  ║"
	@echo "║  ISSUE 1 — Hotspot SSID not visible on phones                   ║"
	@echo "║  ─────────────────────────────────────────────────────────────  ║"
	@echo "║  Causes:                                                         ║"
	@echo "║    a) WEP encryption (40BitEncrypt=1) — iOS 14+/Android 10+     ║"
	@echo "║       silently hides WEP networks in the Wi-Fi list             ║"
	@echo "║    b) Ethernet interface in both PrimaryInterface (source) and  ║"
	@echo "║       SharingDevices (destination) — prevents AP from starting  ║"
	@echo "║    c) InternetSharing not actually running despite plist=on     ║"
	@echo "║  Fix: make hotspot-start   (script handles all three)           ║"
	@echo "║                                                                  ║"
	@echo "║  ISSUE 2 — Internet lost on Mac after hotspot starts            ║"
	@echo "║  ─────────────────────────────────────────────────────────────  ║"
	@echo "║  Cause: Internet Sharing injects bridge interfaces as IPv4      ║"
	@echo "║    default routes with reject flag (!), replacing the real      ║"
	@echo "║    gateway (10.0.0.1 via en9 Ethernet)                          ║"
	@echo "║  Symptom: ping 8.8.8.8 → 100% loss; git push fails             ║"
	@echo "║  Fix: make fix-routes   (renews DHCP on en9, safe + automatic)  ║"
	@echo "║  Manual: sudo ipconfig set en9 DHCP                            ║"
	@echo "║  Nuclear (avoid): sudo route flush  ← disrupts all networking  ║"
	@echo "║                                                                  ║"
	@echo "║  ISSUE 3 — Gallery blank / images missing (403)                 ║"
	@echo "║  ─────────────────────────────────────────────────────────────  ║"
	@echo "║  Cause: osxphotos exports photos as -rw------- (owner-only).   ║"
	@echo "║    nginx worker runs as 'nobody' and cannot read them on        ║"
	@echo "║    external macOS volumes even after chmod 644                  ║"
	@echo "║  Fix: nginx.conf sets 'user sachin staff' so worker inherits   ║"
	@echo "║    owner permissions. Auto-applied by make serve-setup.         ║"
	@echo "║  If it recurs: make clean-view && make build-gallery            ║"
	@echo "║                                                                  ║"
	@echo "║  ISSUE 4 — Phone gets 404 on http://xcasa/natsec               ║"
	@echo "║  ─────────────────────────────────────────────────────────────  ║"
	@echo "║  Cause: browser requests /natsec without trailing slash;        ║"
	@echo "║    nginx location block only matches /natsec/ (with slash)      ║"
	@echo "║  Fix: natsec.conf has 'location = /natsec { return 301 /natsec/}'║"
	@echo "║    Auto-applied by make serve-setup. If it recurs, restart:    ║"
	@echo "║    make serve-stop && make serve                                ║"
	@echo "║                                                                  ║"
	@echo "║  ISSUE 5 — mamba.local doesn't resolve on Android              ║"
	@echo "║  ─────────────────────────────────────────────────────────────  ║"
	@echo "║  Cause: Android does not support mDNS (.local) by default      ║"
	@echo "║  Fix: use IP address instead:  http://192.168.2.1/natsec/      ║"
	@echo "║    dnsmasq resolves 'xcasa' on the hotspot — use that instead  ║"
	@echo "║                                                                  ║"
	@echo "║  CUSTOMER SITE QUICK CHECKLIST                                  ║"
	@echo "║  ─────────────────────────────────────────────────────────────  ║"
	@echo "║  1. Plug in Ethernet cable                                       ║"
	@echo "║  2. make speedtest          verify internet before starting     ║"
	@echo "║  3. make up                 starts everything                   ║"
	@echo "║  4. make check              verify all green                    ║"
	@echo "║  5. If internet dies:  make fix-routes                         ║"
	@echo "║  6. Share: Wi-Fi=natsec  Password=natsec2026  URL=xcasa/natsec ║"
	@echo "║  7. make down               clean teardown before leaving       ║"
	@echo "╚══════════════════════════════════════════════════════════════════╝"
	@echo ""

# ── Clean ──────────────────────────────────────────────────────────────────────
.PHONY: clean-inbox
clean-inbox:
	@echo "Removing all files from $(COLLECTION_INBOX)/..."
	@find "$(COLLECTION_INBOX)" -maxdepth 1 -type f -delete
	@echo "Done."
	@echo ""
