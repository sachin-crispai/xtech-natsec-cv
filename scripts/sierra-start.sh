#!/usr/bin/env bash
# Start the SIERRA secure customer network
# SIERRA is a WPA2 hotspot served by the TAHOE rig (mamba).
# Only authenticated guests on the SIERRA network can view the gallery.
#
# Usage: sudo bash scripts/sierra-start.sh [--password WIFI_PASS]
#        make sierra-start [SIERRA_PASS=yourpass]

set -euo pipefail

SSID="SIERRA"
WIFI_PASS="${SIERRA_PASS:-${1:-sierra2026}}"
GATEWAY="192.168.2.1"
PLIST="/Library/Preferences/SystemConfiguration/com.apple.nat.plist"
AUTH_FILE="/usr/local/etc/nginx/.sierra-auth"
NGINX_CONF="/usr/local/etc/nginx/nginx.conf"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

[[ $EUID -ne 0 ]] && { echo "  ERROR: run with sudo: sudo $0"; exit 1; }

echo ""
echo "  SIERRA — Secure Customer Network"
echo "  ─────────────────────────────────────"

# ── 1. Detect Ethernet (internet source) ──────────────────────────────────────
ETH_DEV=$(networksetup -listallhardwareports 2>/dev/null \
  | awk '/Hardware Port:.*[Ee]thernet/{found=1} found && /Device:/{print $2; found=0}' \
  | while read dev; do
      link=$(ifconfig "$dev" 2>/dev/null | grep -o 'status: [a-z]*' | awk '{print $2}')
      ip=$(ipconfig getifaddr "$dev" 2>/dev/null)
      [ "$link" = "active" ] && [ -n "$ip" ] && echo "$dev" && break
    done)

if [[ -z "$ETH_DEV" ]]; then
  echo "  ERROR: No active Ethernet — plug in cable first."
  exit 1
fi
ETH_GW=$(netstat -rn -f inet 2>/dev/null | awk -v d="$ETH_DEV" '$NF==d && /default/{print $2; exit}')
echo "  Internet : $ETH_DEV (gateway: ${ETH_GW:-unknown})"

# ── 2. Configure Internet Sharing plist ───────────────────────────────────────
echo "  [1/4] Configuring SIERRA hotspot..."
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:NetworkName $SSID"            "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:NetworkPassword $WIFI_PASS"   "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:40BitEncrypt 0"               "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:Channel 0"                    "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:AirPort:Enabled 1"                    "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:PrimaryInterface:Device $ETH_DEV"     "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:PrimaryInterface:Enabled 1"           "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:PrimaryInterface:PrimaryUserReadable Ethernet" "$PLIST"
/usr/libexec/PlistBuddy -c "Set :NAT:Enabled 1"                            "$PLIST"

# Remove Ethernet from SharingDevices if present
IDX=0
while true; do
  VAL=$(/usr/libexec/PlistBuddy -c "Print :NAT:SharingDevices:$IDX" "$PLIST" 2>/dev/null) || break
  if [[ "$VAL" == "$ETH_DEV" ]]; then
    /usr/libexec/PlistBuddy -c "Delete :NAT:SharingDevices:$IDX" "$PLIST"
    break
  fi
  IDX=$((IDX + 1))
done
echo "     SSID: $SSID | WPA2 | Internet via $ETH_DEV"

# ── 3. Restart Internet Sharing ───────────────────────────────────────────────
echo "  [2/4] Starting Internet Sharing..."
pkill -x InternetSharing 2>/dev/null || true
sleep 1
launchctl kickstart -k system/com.apple.NetworkSharing 2>/dev/null || true
sleep 1
[[ -n "$ETH_GW" ]] && { pgrep -x InternetSharing >/dev/null || /usr/libexec/InternetSharing & }
sleep 4

# Restore default route if clobbered
if [[ -n "$ETH_GW" ]] && ! netstat -rn -f inet 2>/dev/null | grep -q "^default.*$ETH_GW"; then
  route delete default 2>/dev/null || true
  route add default "$ETH_GW" 2>/dev/null && echo "     Route restored → $ETH_GW" || true
fi

# ── 4. Deploy SIERRA nginx config ─────────────────────────────────────────────
echo "  [3/4] Deploying SIERRA nginx config..."
mkdir -p /usr/local/etc/nginx/servers
cp "$REPO_ROOT/infra/nginx/sierra.conf"  /usr/local/etc/nginx/servers/sierra.conf
cp "$REPO_ROOT/infra/nginx/nginx.conf"   /usr/local/etc/nginx/nginx.conf

# Validate
/usr/local/opt/nginx/bin/nginx -t -c "$NGINX_CONF" 2>&1 \
  | grep -v '\[warn\]' | grep -v 'pid' | sed 's/^/     /' || true

# Ensure auth file exists (locked until guest added)
[[ -f "$AUTH_FILE" ]] || { touch "$AUTH_FILE"; chmod 640 "$AUTH_FILE"; }

# Start or reload nginx
if ps aux | grep -q "[n]ginx: master"; then
  /usr/local/opt/nginx/bin/nginx -s reload -c "$NGINX_CONF" 2>/dev/null && \
    echo "     nginx reloaded." || true
else
  /usr/local/opt/nginx/bin/nginx -c "$NGINX_CONF" 2>/dev/null && \
    echo "     nginx started." || true
fi

# ── 5. Start dnsmasq for SIERRA ───────────────────────────────────────────────
echo "  [4/4] Starting dnsmasq (tahoe → $GATEWAY)..."
mkdir -p /usr/local/etc/dnsmasq.d
cp "$REPO_ROOT/infra/dnsmasq/sierra.conf" /usr/local/etc/dnsmasq.d/sierra.conf

# Detect bridge interface
BRIDGE_IF=$(ifconfig | awk '/^bridge/{iface=$1} /inet 192\.168\.2\./{print iface; exit}' | tr -d ':')
[[ -n "$BRIDGE_IF" ]] && sed -i '' "s/^interface=.*/interface=$BRIDGE_IF/" \
  /usr/local/etc/dnsmasq.d/sierra.conf

pkill -f "dnsmasq.*sierra" 2>/dev/null || true
sleep 1
/usr/local/sbin/dnsmasq \
  --conf-file=/usr/local/etc/dnsmasq.d/sierra.conf \
  --pid-file=/tmp/dnsmasq-sierra.pid
echo "     dnsmasq running (PID: $(cat /tmp/dnsmasq-sierra.pid 2>/dev/null || echo '?'))"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║  SIERRA network is LIVE                                  ║"
echo "  ╠══════════════════════════════════════════════════════════╣"
echo "  ║  Wi-Fi SSID  : $SSID"
echo "  ║  Wi-Fi Pass  : $WIFI_PASS"
echo "  ╠══════════════════════════════════════════════════════════╣"
echo "  ║  Gallery URL : http://tahoe/gallery/                    ║"
echo "  ║  (requires guest credentials — see: make add-guest)     ║"
echo "  ╠══════════════════════════════════════════════════════════╣"
echo "  ║  Next steps:                                            ║"
echo "  ║    make add-guest NAME=john   create guest login        ║"
echo "  ║    make list-guests           show active guests        ║"
echo "  ║    make revoke-all-guests     lock after demo           ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo ""
