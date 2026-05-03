#!/usr/bin/env bash
# Configure and start the 'natsec' Wi-Fi hotspot on mamba
#
# Prerequisites:
#   - Ethernet cable plugged in (USB-C, Thunderbolt, or Display Port adapter)
#   - Mac gets internet from Ethernet; Wi-Fi is freed for the hotspot
#
# What this does:
#   1. Auto-detects the active Ethernet interface (internet source)
#   2. Configures macOS Internet Sharing: Ethernet → natsec Wi-Fi hotspot (WPA2)
#   3. Starts dnsmasq so 'xcasa' resolves to the Mac gateway on the hotspot
#   4. Reloads nginx so it serves on the hotspot IP
#
# Usage:
#   sudo ./scripts/setup-hotspot.sh [--password <wifi-password>]
#   sudo ./scripts/setup-hotspot.sh --stop

set -euo pipefail

HOTSPOT_SSID="natsec"
HOTSPOT_IP="192.168.2.1"
PLIST="/Library/Preferences/SystemConfiguration/com.apple.nat.plist"
DNSMASQ_CONF="/usr/local/etc/dnsmasq.d/natsec-hotspot.conf"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WIFI_PASSWORD="natsec2026"
STOP=false

# ── Args ───────────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --password) WIFI_PASSWORD="$2"; shift 2 ;;
    --stop)     STOP=true; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

[[ $EUID -ne 0 ]] && { echo "  ERROR: run with sudo: sudo $0 $*"; exit 1; }

# ── Stop ───────────────────────────────────────────────────────────────────────
if $STOP; then
  echo ""
  echo "  Stopping natsec hotspot..."
  launchctl unload /System/Library/LaunchDaemons/com.apple.NetworkSharing.plist 2>/dev/null || true
  pkill -f "dnsmasq.*natsec" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :NAT:Enabled 0"          "$PLIST" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Set :NAT:AirPort:Enabled 0"  "$PLIST" 2>/dev/null || true
  echo "  Hotspot stopped."
  echo ""
  exit 0
fi

# ── Detect Ethernet interface ──────────────────────────────────────────────────
# Finds the first Ethernet-class interface with active link + IP.
# Works regardless of adapter slot, port number, or brand.
detect_ethernet() {
  # Get all BSD device names for hardware ports containing "Ethernet"
  local devs
  devs=$(networksetup -listallhardwareports 2>/dev/null \
    | awk '/Hardware Port:.*[Ee]thernet/{found=1} found && /Device:/{print $2; found=0}')

  for dev in $devs; do
    # Must have active link (cable physically plugged in)
    local link
    link=$(ifconfig "$dev" 2>/dev/null | grep -o 'status: [a-z]*' | awk '{print $2}')
    [[ "$link" != "active" ]] && continue

    # Must have an IP address
    local ip
    ip=$(ipconfig getifaddr "$dev" 2>/dev/null || true)
    [[ -z "$ip" ]] && continue

    echo "$dev"
    return 0
  done
  return 1
}

echo ""
echo "  natsec Hotspot Setup"
echo "  ───────────────────────────────────"

ETH_DEV=$(detect_ethernet || true)

if [[ -z "$ETH_DEV" ]]; then
  echo ""
  echo "  ✗ No Ethernet with internet found."
  echo ""
  echo "  Plug in your Ethernet cable (USB-C/Thunderbolt adapter), then re-run:"
  echo "    make hotspot-start"
  echo ""
  echo "  Available adapters on this Mac:"
  networksetup -listallhardwareports 2>/dev/null \
    | awk '/Hardware Port:.*[Ee]thernet/{show=1} show && /Device:/{print "    "$0; show=0}'
  echo ""
  exit 1
fi

ETH_IP=$(ipconfig getifaddr "$ETH_DEV")
ETH_NAME=$(networksetup -listallhardwareports 2>/dev/null \
  | awk -v d="$ETH_DEV" '/Hardware Port:/{name=substr($0,17)} /Device:/{if($2==d) print name}' | head -1)

echo "  Internet : $ETH_NAME ($ETH_DEV) → $ETH_IP  ✓"
echo "  Hotspot  : $HOTSPOT_SSID (WPA2) on Wi-Fi (en0)"
echo "  Gateway  : $HOTSPOT_IP"
echo "  Hostname : xcasa → $HOTSPOT_IP"
echo ""

# ── Step 1: Configure plist ────────────────────────────────────────────────────
echo "  [1/4] Configuring Internet Sharing plist..."

# Set Ethernet as the internet source (share FROM)
/usr/libexec/PlistBuddy -c "Set :NAT:PrimaryInterface:Device $ETH_DEV"    "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:PrimaryInterface:Enabled 1"          "$PLIST"
# Wrap label in quotes to prevent PlistBuddy truncating multi-word strings
/usr/libexec/PlistBuddy -c "Set :NAT:PrimaryInterface:PrimaryUserReadable Ethernet" "$PLIST"

# CRITICAL: Remove the Ethernet device from SharingDevices —
# a device cannot be both the internet source AND a sharing destination.
# This is the #1 reason the hotspot doesn't broadcast.
IDX=0
while true; do
  VAL=$(/usr/libexec/PlistBuddy -c "Print :NAT:SharingDevices:$IDX" "$PLIST" 2>/dev/null) || break
  if [[ "$VAL" == "$ETH_DEV" ]]; then
    /usr/libexec/PlistBuddy -c "Delete :NAT:SharingDevices:$IDX" "$PLIST"
    echo "     Removed $ETH_DEV from SharingDevices (was source+destination conflict)"
    break
  fi
  IDX=$((IDX + 1))
done

# Hotspot: WPA2, visible SSID, auto channel
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:NetworkName $HOTSPOT_SSID"       "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:NetworkPassword $WIFI_PASSWORD"  "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:40BitEncrypt 0"                  "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:Channel 0"                       "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:Enabled 1"                       "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:Enabled 1"                               "$PLIST"

echo "     Source: $ETH_DEV ($ETH_NAME) | SSID: $HOTSPOT_SSID | WPA2 | Channel: auto"

# ── Step 2: Restart Internet Sharing ──────────────────────────────────────────
echo "  [2/4] Restarting Internet Sharing..."

# Snapshot the Ethernet gateway BEFORE Internet Sharing touches routing
ETH_GW=$(netstat -rn -f inet 2>/dev/null | awk -v dev="$ETH_DEV" '$NF==dev && /default/{print $2; exit}')
[ -z "$ETH_GW" ] && ETH_GW=$(netstat -rn | awk '/default.*[0-9]+\.[0-9]+/{print $2; exit}')
echo "     Ethernet gateway: ${ETH_GW:-unknown}"

# Kill any existing InternetSharing process cleanly
pkill -x InternetSharing 2>/dev/null || true
sleep 1

# NetworkSharing is OnDemand — 'launchctl load' only registers it, never starts it.
# Use 'kickstart -k' (kill + force start) to actually run it.
launchctl kickstart -k system/com.apple.NetworkSharing 2>/dev/null || {
  # Fallback for older macOS: unload/load + direct binary
  launchctl unload /System/Library/LaunchDaemons/com.apple.NetworkSharing.plist 2>/dev/null || true
  sleep 1
  launchctl load   /System/Library/LaunchDaemons/com.apple.NetworkSharing.plist 2>/dev/null || true
}
sleep 2

# Also launch InternetSharing binary directly as belt-and-suspenders
if ! pgrep -x InternetSharing >/dev/null 2>&1; then
  /usr/libexec/InternetSharing &
  echo "     Started InternetSharing directly (PID $!)"
fi
sleep 4

echo "     Internet Sharing started."

# Restore Ethernet default route — Internet Sharing often clobbers it
if [[ -n "$ETH_GW" ]]; then
  if ! netstat -rn -f inet 2>/dev/null | grep -q "^default.*$ETH_GW"; then
    route delete default 2>/dev/null || true
    route add default "$ETH_GW" 2>/dev/null \
      && echo "     Default route restored → $ETH_GW via $ETH_DEV" \
      || echo "     ⚠  Could not restore route — run: sudo route add default $ETH_GW"
  else
    echo "     Default route intact ($ETH_GW) — no fix needed"
  fi
fi

# Wait for bridge to get its IP
echo "     Waiting for hotspot bridge..."
BRIDGE_IF=""
for i in 1 2 3 4 5; do
  BRIDGE_IF=$(ifconfig | awk '/^bridge/{iface=$1} /inet 192\.168\.2\./{print iface; exit}' | tr -d ':')
  [[ -n "$BRIDGE_IF" ]] && break
  sleep 2
done

if [[ -z "$BRIDGE_IF" ]]; then
  echo "     ⚠  Bridge IP not detected yet — hotspot may take a moment to appear."
  BRIDGE_IF="bridge100"
else
  echo "     Bridge active: $BRIDGE_IF ($HOTSPOT_IP)"
fi

# ── Step 3: dnsmasq for xcasa hostname ────────────────────────────────────────
echo "  [3/4] Starting dnsmasq (xcasa → $HOTSPOT_IP)..."
mkdir -p /usr/local/etc/dnsmasq.d
cp "$REPO_ROOT/infra/dnsmasq/natsec-hotspot.conf" "$DNSMASQ_CONF"
sed -i '' "s/^interface=.*/interface=$BRIDGE_IF/" "$DNSMASQ_CONF"

pkill -f "dnsmasq.*natsec" 2>/dev/null || true
sleep 1
/usr/local/sbin/dnsmasq \
  --conf-file="$DNSMASQ_CONF" \
  --pid-file=/tmp/dnsmasq-natsec.pid
echo "     dnsmasq running (PID: $(cat /tmp/dnsmasq-natsec.pid 2>/dev/null || echo '?'))"

# ── Step 4: Reload nginx ───────────────────────────────────────────────────────
echo "  [4/4] Reloading nginx..."
NGINX_BIN="/usr/local/opt/nginx/bin/nginx"
NGINX_CONF="/usr/local/etc/nginx/nginx.conf"
if pgrep -x nginx >/dev/null 2>&1; then
  "$NGINX_BIN" -s reload -c "$NGINX_CONF" 2>/dev/null \
    && echo "     nginx reloaded." \
    || echo "     nginx reload failed — run: make serve"
else
  echo "     nginx not running — run: make serve"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "  ╔═══════════════════════════════════════════════════╗"
echo "  ║  natsec hotspot LIVE                              ║"
echo "  ╠═══════════════════════════════════════════════════╣"
echo "  ║  Wi-Fi  : natsec  |  Password: $WIFI_PASSWORD     ║"
echo "  ║  Internet via: $ETH_NAME ($ETH_DEV)               ║"
echo "  ╠═══════════════════════════════════════════════════╣"
echo "  ║  Connect phone to 'natsec', then open:            ║"
echo "  ║    http://xcasa/natsec/    ← friendly             ║"
echo "  ║    http://$HOTSPOT_IP/natsec/ ← IP fallback       ║"
echo "  ╚═══════════════════════════════════════════════════╝"
echo ""
