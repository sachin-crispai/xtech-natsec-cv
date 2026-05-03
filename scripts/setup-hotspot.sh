#!/usr/bin/env bash
# Configure and start the 'natsec' Wi-Fi hotspot on mamba
#
# What this does:
#   1. Sets SSID to 'natsec' + WPA2 password in macOS Internet Sharing plist
#   2. Enables Internet Sharing (Mac shares en0 internet via Wi-Fi soft-AP)
#   3. Starts dnsmasq so 'xcasa' resolves to the Mac on the hotspot network
#   4. Ensures nginx serves on the hotspot IP (192.168.2.1)
#
# Usage:
#   sudo ./scripts/setup-hotspot.sh [--password <wifi-password>]
#   sudo ./scripts/setup-hotspot.sh --stop

set -euo pipefail

HOTSPOT_SSID="natsec"
HOTSPOT_CHANNEL=6
HOTSPOT_IP="192.168.2.1"         # Mac's IP on the hotspot bridge
PLIST="/Library/Preferences/SystemConfiguration/com.apple.nat.plist"
DNSMASQ_CONF="/usr/local/etc/dnsmasq.d/natsec-hotspot.conf"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIFI_PASSWORD="natsec2026"       # default — override with --password
STOP=false

# ── Args ───────────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --password) WIFI_PASSWORD="$2"; shift 2 ;;
    --stop)     STOP=true; shift ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "  ERROR: run with sudo: sudo $0 $*"
  exit 1
fi

# ── Stop ───────────────────────────────────────────────────────────────────────
if $STOP; then
  echo ""
  echo "  Stopping natsec hotspot..."
  launchctl unload /System/Library/LaunchDaemons/com.apple.NetworkSharing.plist 2>/dev/null || true
  pkill -f "dnsmasq.*natsec" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :NAT:Enabled 0" "$PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :NAT:AirPort:Enabled 0" "$PLIST" 2>/dev/null || true
  echo "  Hotspot stopped."
  echo ""
  exit 0
fi

echo ""
echo "  natsec Hotspot Setup"
echo "  ───────────────────────────────────"
echo "  SSID     : $HOTSPOT_SSID"
echo "  Password : $WIFI_PASSWORD"
echo "  Gateway  : $HOTSPOT_IP"
echo "  Hostname : xcasa  →  $HOTSPOT_IP"
echo ""

# ── Step 1: Configure Internet Sharing plist ───────────────────────────────────
echo "  [1/4] Configuring Internet Sharing..."
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:NetworkName $HOTSPOT_SSID"       "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:NetworkPassword $WIFI_PASSWORD"  "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:Channel 0"                       "$PLIST"  # 0 = auto
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:40BitEncrypt 0"                  "$PLIST"  # 0 = WPA2 (not WEP)
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:Enabled 1"                       "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:Enabled 1"                               "$PLIST"
echo "     SSID: '$HOTSPOT_SSID' | Encryption: WPA2 | Channel: auto"

# ── Step 2: Start Internet Sharing ────────────────────────────────────────────
echo "  [2/4] Starting Internet Sharing..."
launchctl unload /System/Library/LaunchDaemons/com.apple.NetworkSharing.plist 2>/dev/null || true
sleep 1
launchctl load  /System/Library/LaunchDaemons/com.apple.NetworkSharing.plist
sleep 3
echo "     Internet Sharing started."

# ── Step 3: Deploy and start dnsmasq for xcasa hostname ───────────────────────
echo "  [3/4] Starting dnsmasq (xcasa hostname)..."
mkdir -p /usr/local/etc/dnsmasq.d
cp "$REPO_ROOT/infra/dnsmasq/natsec-hotspot.conf" "$DNSMASQ_CONF"

# Find the actual bridge interface that got 192.168.2.x
BRIDGE_IF=$(ifconfig | awk '/^bridge/{iface=$1} /inet 192\.168\.2\./{print iface; exit}' | tr -d ':')
if [[ -z "$BRIDGE_IF" ]]; then
  BRIDGE_IF="bridge100"
  echo "     Warning: could not detect bridge — defaulting to bridge100"
else
  echo "     Hotspot bridge: $BRIDGE_IF"
  # Update dnsmasq config with actual interface
  sed -i '' "s/^interface=.*/interface=$BRIDGE_IF/" "$DNSMASQ_CONF"
fi

pkill -f "dnsmasq.*natsec" 2>/dev/null || true
sleep 1
/usr/local/sbin/dnsmasq --conf-file="$DNSMASQ_CONF" --pid-file=/tmp/dnsmasq-natsec.pid
echo "     dnsmasq started (PID: $(cat /tmp/dnsmasq-natsec.pid 2>/dev/null || echo '?'))"

# ── Step 4: Update nginx server_name to include xcasa ─────────────────────────
echo "  [4/4] Confirming nginx is serving on hotspot IP..."
NGINX_BIN="/usr/local/opt/nginx/bin/nginx"
NGINX_CONF="/usr/local/etc/nginx/nginx.conf"
if pgrep -x nginx >/dev/null 2>&1; then
  "$NGINX_BIN" -s reload -c "$NGINX_CONF" 2>/dev/null && echo "     nginx reloaded." || echo "     nginx reload skipped."
else
  echo "     nginx not running — start it with: make serve"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════════════════════╗"
echo "  ║  natsec hotspot is LIVE                              ║"
echo "  ╠══════════════════════════════════════════════════════╣"
echo "  ║  Wi-Fi SSID  : natsec                               ║"
echo "  ║  Password    : $WIFI_PASSWORD                        ║"
echo "  ╠══════════════════════════════════════════════════════╣"
echo "  ║  After connecting, open:                            ║"
echo "  ║    http://xcasa/natsec/       ← friendly hostname   ║"
echo "  ║    http://$HOTSPOT_IP/natsec/  ← IP fallback          ║"
echo "  ╚══════════════════════════════════════════════════════╝"
echo ""
