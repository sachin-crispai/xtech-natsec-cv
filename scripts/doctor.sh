#!/usr/bin/env bash
# NATSEC-CV Doctor — deep diagnostic for hotspot + full stack
# Read-only. Prints PASS/FAIL for every known failure mode + exact fix commands.
# Usage: make doctor   or   bash scripts/doctor.sh

PASS="✅ PASS"
FAIL="❌ FAIL"
WARN="⚠️  WARN"

ISSUES=0
WARNINGS=0

pass() { printf "  %-52s %s\n" "$1" "$PASS"; }
fail() { printf "  %-52s %s\n" "$1" "$FAIL"; ISSUES=$((ISSUES+1)); }
warn() { printf "  %-52s %s\n" "$1" "$WARN"; WARNINGS=$((WARNINGS+1)); }
fix()  { echo   "         → fix: $*"; }
info() { echo   "         ℹ  $*"; }
sep()  { echo   ""; echo "  ── $1 ──$(printf '%0.s─' $(seq 1 $((50-${#1}))))"; }

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  NATSEC-CV Doctor  ·  $(date '+%Y-%m-%d %H:%M')                    ║"
echo "╚══════════════════════════════════════════════════════════╝"

# ══════════════════════════════════════════════════════════════
sep "1. Ethernet — internet source"
# ══════════════════════════════════════════════════════════════

ETH_DEV=$(networksetup -listallhardwareports 2>/dev/null \
  | awk '/Hardware Port:.*[Ee]thernet/{found=1} found && /Device:/{print $2; found=0}' \
  | while read dev; do
      link=$(ifconfig "$dev" 2>/dev/null | grep -o 'status: [a-z]*' | awk '{print $2}')
      ip=$(ipconfig getifaddr "$dev" 2>/dev/null)
      [ "$link" = "active" ] && [ -n "$ip" ] && echo "$dev" && break
    done)

ETH_IP=$(ipconfig getifaddr "$ETH_DEV" 2>/dev/null)

if [ -n "$ETH_DEV" ] && [ -n "$ETH_IP" ]; then
  pass "Ethernet cable plugged in ($ETH_DEV: $ETH_IP)"
else
  fail "No active Ethernet interface found"
  fix "Plug in Ethernet cable (USB-C or Thunderbolt adapter)"
  fix "Then: make hotspot-start"
fi

# IPv4 default route
IPV4_GW=$(netstat -rn -f inet 2>/dev/null | awk '/^default.*[0-9]+\.[0-9]+/{print $2; exit}')
if [ -n "$IPV4_GW" ] && ping -c 1 -t 2 "$IPV4_GW" >/dev/null 2>&1; then
  pass "IPv4 default route present ($IPV4_GW)"
else
  fail "No IPv4 default route — internet broken on Mac"
  fix "make fix-routes   (safe DHCP renew on $ETH_DEV)"
  fix "or: sudo ipconfig set ${ETH_DEV:-en9} DHCP"
fi

# Internet reachability
if ping -c 1 -t 3 8.8.8.8 >/dev/null 2>&1; then
  pass "Internet reachable (8.8.8.8)"
else
  fail "Internet unreachable"
  fix "make fix-routes"
fi

# ══════════════════════════════════════════════════════════════
sep "2. Internet Sharing plist"
# ══════════════════════════════════════════════════════════════
PLIST="/Library/Preferences/SystemConfiguration/com.apple.nat.plist"

NAT_ENABLED=$(/usr/libexec/PlistBuddy -c "Print :NAT:Enabled"              "$PLIST" 2>/dev/null)
AP_ENABLED=$(/usr/libexec/PlistBuddy  -c "Print :NAT:AirPort:Enabled"      "$PLIST" 2>/dev/null)
AP_SSID=$(/usr/libexec/PlistBuddy     -c "Print :NAT:AirPort:NetworkName"  "$PLIST" 2>/dev/null)
AP_ENC=$(/usr/libexec/PlistBuddy      -c "Print :NAT:AirPort:40BitEncrypt" "$PLIST" 2>/dev/null)
PRI_DEV=$(/usr/libexec/PlistBuddy     -c "Print :NAT:PrimaryInterface:Device"   "$PLIST" 2>/dev/null)
PRI_EN=$(/usr/libexec/PlistBuddy      -c "Print :NAT:PrimaryInterface:Enabled"  "$PLIST" 2>/dev/null)

[ "$NAT_ENABLED" = "1" ] \
  && pass "Internet Sharing enabled (NAT:Enabled=1)" \
  || { fail "Internet Sharing disabled in plist"; fix "make hotspot-start"; }

[ "$AP_ENABLED" = "1" ] \
  && pass "AirPort hotspot enabled (AirPort:Enabled=1)" \
  || { fail "AirPort hotspot disabled in plist"; fix "make hotspot-start"; }

[ "$AP_SSID" = "natsec" ] \
  && pass "SSID set correctly (natsec)" \
  || { fail "SSID is '$AP_SSID' — expected 'natsec'"; fix "make hotspot-start"; }

[ "$AP_ENC" = "0" ] \
  && pass "Encryption is WPA2 (40BitEncrypt=0)" \
  || { fail "Encryption is WEP (40BitEncrypt=1) — phones won't see it"; fix "make hotspot-start"; }

# Check PrimaryInterface is set to Ethernet, not Wi-Fi
if [ -n "$PRI_DEV" ] && [ "$PRI_DEV" != "en0" ] && [ "$PRI_EN" = "1" ]; then
  pass "PrimaryInterface set to Ethernet ($PRI_DEV, Enabled=1)"
else
  fail "PrimaryInterface misconfigured (Device=$PRI_DEV, Enabled=$PRI_EN)"
  fix "make hotspot-start   (auto-detects and sets correct Ethernet interface)"
fi

# Check Ethernet not in SharingDevices (source+destination conflict)
SHARING_HAS_ETH=$(/usr/libexec/PlistBuddy -c "Print :NAT:SharingDevices" "$PLIST" 2>/dev/null \
  | grep -c "${ETH_DEV:-en9}" || echo 0)
if [ "$SHARING_HAS_ETH" = "0" ]; then
  pass "Ethernet not in SharingDevices (no source/dest conflict)"
else
  fail "Ethernet ($ETH_DEV) in SharingDevices AND PrimaryInterface — conflict!"
  info "This is the #1 reason hotspot doesn't broadcast"
  fix "make hotspot-start   (script removes the conflict automatically)"
fi

# ══════════════════════════════════════════════════════════════
sep "3. InternetSharing process"
# ══════════════════════════════════════════════════════════════

IS_PID=$(pgrep -x InternetSharing 2>/dev/null | head -1)
if [ -n "$IS_PID" ]; then
  pass "InternetSharing process running (PID $IS_PID)"
else
  fail "InternetSharing process not running"
  fix "make hotspot-start"
fi

# Hotspot bridge with 192.168.2.x
BRIDGE_IF=""
BRIDGE_IP=""
for br in bridge100 bridge101 bridge102 bridge103; do
  IP=$(ipconfig getifaddr "$br" 2>/dev/null)
  if echo "$IP" | grep -q "^192\.168\.2\."; then
    BRIDGE_IF="$br"; BRIDGE_IP="$IP"; break
  fi
done

if [ -n "$BRIDGE_IF" ]; then
  pass "Hotspot bridge active ($BRIDGE_IF: $BRIDGE_IP)"
else
  fail "No hotspot bridge with 192.168.2.x IP — AP not broadcasting"
  info "InternetSharing may be running but not fully started"
  fix "make hotspot-stop && make hotspot-start"
fi

# Wi-Fi interface in AP mode
EN0_STATUS=$(ifconfig en0 2>/dev/null | grep -o 'status: [a-z]*' | awk '{print $2}')
if [ "$EN0_STATUS" = "active" ]; then
  EN0_IP=$(ipconfig getifaddr en0 2>/dev/null)
  if [ -n "$EN0_IP" ]; then
    warn "en0 is active as Wi-Fi CLIENT (IP: $EN0_IP) — not in AP/hotspot mode"
    info "Hotspot and Wi-Fi client are mutually exclusive on Intel Macs"
    info "Disconnect from Wi-Fi or use Ethernet-only and let hotspot use en0"
  else
    pass "en0 active (likely in AP mode — no client IP assigned)"
  fi
elif [ "$EN0_STATUS" = "inactive" ]; then
  warn "en0 (Wi-Fi) is inactive — hotspot not broadcasting yet"
  info "Internet Sharing should activate en0 as AP when fully started"
  fix "make hotspot-stop && make hotspot-start"
else
  info "en0 status: ${EN0_STATUS:-unknown}"
fi

# ══════════════════════════════════════════════════════════════
sep "4. nginx web server"
# ══════════════════════════════════════════════════════════════

NGINX_BIN="/usr/local/opt/nginx/bin/nginx"
NGINX_CONF="/usr/local/etc/nginx/nginx.conf"

if [ -f "$NGINX_BIN" ]; then
  pass "nginx binary present"
else
  fail "nginx not installed"
  fix "brew install nginx && make serve-setup"
fi

# nginx -t needs root to write the pid file — check only for syntax/config errors,
# not pid permission errors (which are harmless when checking without sudo)
NGINX_TEST=$("$NGINX_BIN" -t -c "$NGINX_CONF" 2>&1)
NGINX_ERRORS=$(echo "$NGINX_TEST" | grep -v '\[warn\]' | grep '\[emerg\]\|\[error\]\|\[crit\]' \
  | grep -v 'Permission denied.*pid' | grep -v 'open().*pid')
if [ -z "$NGINX_ERRORS" ]; then
  pass "nginx config syntax valid"
else
  fail "nginx config has errors"
  fix "make serve-setup   (redeploys infra/nginx/ configs)"
  echo "$NGINX_ERRORS" | sed 's/^/         /'
fi

NGINX_PID=$(pgrep -x nginx 2>/dev/null | head -1)
if [ -n "$NGINX_PID" ]; then
  NGINX_USER=$(ps -o user= -p "$NGINX_PID" 2>/dev/null | tr -d ' ')
  pass "nginx running (PID $NGINX_PID, master user: ${NGINX_USER:-?})"
else
  fail "nginx not running"
  fix "make serve"
fi

HTTP=$(curl -so /dev/null -w "%{http_code}" --connect-timeout 2 \
  http://localhost/natsec/ 2>/dev/null)
[ "$HTTP" = "200" ] \
  && pass "Gallery responds HTTP 200 on localhost" \
  || { fail "Gallery not responding (got: $HTTP)"; fix "make serve-stop && make serve"; }

# File permissions
BAD_PERMS=$(find platform/collection/view -type f ! -perm -o+r 2>/dev/null | wc -l | tr -d ' ')
[ "$BAD_PERMS" = "0" ] \
  && pass "All gallery files world-readable (nginx can serve them)" \
  || { fail "$BAD_PERMS file(s) not world-readable — nginx returns 403"
       fix "find platform/collection/view -type f -exec chmod 644 {} \\;"; }

# ══════════════════════════════════════════════════════════════
sep "5. dnsmasq — xcasa hostname"
# ══════════════════════════════════════════════════════════════

DNSMASQ_PID=$(cat /tmp/dnsmasq-natsec.pid 2>/dev/null)
if [ -n "$DNSMASQ_PID" ] && ps -p "$DNSMASQ_PID" >/dev/null 2>&1; then
  pass "dnsmasq running (PID $DNSMASQ_PID)"
else
  fail "dnsmasq not running — 'xcasa' won't resolve on hotspot"
  fix "make hotspot-start"
fi

DNSMASQ_CONF="/usr/local/etc/dnsmasq.d/natsec-hotspot.conf"
[ -f "$DNSMASQ_CONF" ] \
  && pass "dnsmasq config present" \
  || { fail "dnsmasq config missing"; fix "make hotspot-start"; }

# ══════════════════════════════════════════════════════════════
sep "6. System — Touch ID + tools"
# ══════════════════════════════════════════════════════════════

[ -f "/etc/pam.d/sudo_local" ] && grep -q "pam_tid" /etc/pam.d/sudo_local \
  && pass "Touch ID for sudo active" \
  || { warn "Touch ID for sudo not enabled"; fix "make enable-touchid"; }

for tool in ffmpeg osxphotos speedtest-cli dnsmasq; do
  command -v "$tool" >/dev/null 2>&1 \
    && pass "$tool installed" \
    || { warn "$tool not installed"; fix "brew install $tool  (or: make install-deps)"; }
done

# ══════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════
echo ""
echo "  ════════════════════════════════════════════════════════"
if [ "$ISSUES" = "0" ] && [ "$WARNINGS" = "0" ]; then
  echo "  ✅ All checks passed — stack is healthy."
elif [ "$ISSUES" = "0" ]; then
  echo "  ⚠️  $WARNINGS warning(s), 0 failures — mostly good."
else
  echo "  ❌ $ISSUES failure(s), $WARNINGS warning(s) found."
  echo ""
  echo "  Quick fix sequence:"
  echo "    make fix-routes      (if internet is broken)"
  echo "    make hotspot-start   (fixes hotspot config + restarts)"
  echo "    make serve           (starts nginx)"
  echo "    make doctor          (re-run to verify)"
fi
echo "  ════════════════════════════════════════════════════════"
echo ""
