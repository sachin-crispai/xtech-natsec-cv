#!/usr/bin/env bash
# SIERRA guest credential manager
# Adds / lists / revokes access to the authenticated gallery
#
# Usage:
#   bash scripts/manage-guests.sh add    NAME [PASSWORD]
#   bash scripts/manage-guests.sh list
#   bash scripts/manage-guests.sh revoke NAME
#   bash scripts/manage-guests.sh revoke-all
#
# Makefile shortcuts:
#   make add-guest    NAME=john [PASS=secret]
#   make list-guests
#   make revoke-guest NAME=john
#   make revoke-all-guests

set -euo pipefail

AUTH_FILE="/usr/local/etc/nginx/.sierra-auth"
GALLERY_URL="http://tahoe/gallery/"
WIFI_SSID="SIERRA"
ACTION="${1:-list}"
NAME="${2:-}"
PASS="${3:-}"

# ── Helpers ────────────────────────────────────────────────────────────────────
require_name() {
  if [[ -z "$NAME" ]]; then
    echo "  ERROR: NAME required. Usage: make add-guest NAME=john"
    exit 1
  fi
}

ensure_auth_file() {
  if [[ ! -f "$AUTH_FILE" ]]; then
    sudo touch "$AUTH_FILE"
    sudo chmod 640 "$AUTH_FILE"
  fi
}

qr_url() {
  local url="$1"
  # Print URL as a simple ASCII QR hint (actual QR via qrencode if available)
  if command -v qrencode >/dev/null 2>&1; then
    qrencode -t ANSIUTF8 "$url" 2>/dev/null
  else
    echo "  (install qrencode for QR: brew install qrencode)"
  fi
}

# ── Actions ────────────────────────────────────────────────────────────────────
case "$ACTION" in

  add)
    require_name
    ensure_auth_file

    # Generate random password if not supplied
    if [[ -z "$PASS" ]]; then
      PASS=$(openssl rand -base64 6 | tr -d '=/+' | head -c 8)
    fi

    # Add or update user in auth file
    sudo /usr/sbin/htpasswd -bB "$AUTH_FILE" "$NAME" "$PASS" 2>/dev/null && \
      echo "" || { echo "  ERROR: htpasswd failed"; exit 1; }

    # Reload nginx to pick up new credential
    /usr/local/opt/nginx/bin/nginx -s reload -c /usr/local/etc/nginx/nginx.conf \
      2>/dev/null || true

    echo ""
    echo "  ╔══════════════════════════════════════════════════╗"
    echo "  ║  SIERRA — Guest Access Created                   ║"
    echo "  ╠══════════════════════════════════════════════════╣"
    echo "  ║  Name     : $NAME"
    echo "  ╠══════════════════════════════════════════════════╣"
    echo "  ║  Step 1 — Join Wi-Fi:                           ║"
    echo "  ║    Network  : $WIFI_SSID"
    echo "  ║    Password : (SIERRA Wi-Fi password)           ║"
    echo "  ╠══════════════════════════════════════════════════╣"
    echo "  ║  Step 2 — Open gallery:                         ║"
    echo "  ║    URL      : $GALLERY_URL"
    echo "  ║    Username : $NAME"
    echo "  ║    Password : $PASS"
    echo "  ╚══════════════════════════════════════════════════╝"
    echo ""
    echo "  Authenticated URL (scan or tap):"
    AUTH_URL="http://${NAME}:${PASS}@tahoe/gallery/"
    echo "  $AUTH_URL"
    echo ""
    qr_url "$AUTH_URL"
    ;;

  list)
    echo ""
    echo "  SIERRA — Active guests"
    echo "  ──────────────────────"
    if [[ -f "$AUTH_FILE" ]] && [[ -s "$AUTH_FILE" ]]; then
      COUNT=0
      while IFS=: read -r user _; do
        [[ -n "$user" ]] && echo "  • $user" && COUNT=$((COUNT+1))
      done < "$AUTH_FILE"
      echo ""
      echo "  Total: $COUNT guest(s)"
    else
      echo "  No guests configured."
      echo "  Add one: make add-guest NAME=john"
    fi
    echo ""
    ;;

  revoke)
    require_name
    if [[ ! -f "$AUTH_FILE" ]]; then
      echo "  No auth file found — nothing to revoke."
      exit 0
    fi
    sudo /usr/sbin/htpasswd -D "$AUTH_FILE" "$NAME" 2>/dev/null \
      && echo "  ✓ Revoked access for: $NAME" \
      || echo "  User '$NAME' not found in auth file."
    /usr/local/opt/nginx/bin/nginx -s reload -c /usr/local/etc/nginx/nginx.conf \
      2>/dev/null || true
    ;;

  revoke-all)
    echo ""
    read -r -p "  Revoke ALL guest access? [y/N]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
      sudo rm -f "$AUTH_FILE"
      /usr/local/opt/nginx/bin/nginx -s reload -c /usr/local/etc/nginx/nginx.conf \
        2>/dev/null || true
      echo "  ✓ All guests revoked. Gallery is locked."
    else
      echo "  Cancelled."
    fi
    echo ""
    ;;

  *)
    echo "Usage: $0 {add NAME [PASS] | list | revoke NAME | revoke-all}"
    exit 1
    ;;
esac
