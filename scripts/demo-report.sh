#!/usr/bin/env bash
# Full demo client diagnostic — run when clients can't connect
# Usage: make demo-report

set -euo pipefail

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  DEMO CLIENT DIAGNOSTIC — $(date '+%Y-%m-%d %H:%M:%S')       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── 1. VPN tunnel status ───────────────────────────────────────────────────────
echo "── 1. WireGuard (utun9 · port 51821) ────────────────────────────────────"
if ! sudo wg show utun9 >/dev/null 2>&1; then
  echo "  ✗ utun9 NOT RUNNING"
  echo "  Fix: make vpn-start"
  exit 0
fi

sudo wg show utun9 dump 2>/dev/null | tail -n +2 | while IFS=$'\t' read -r pubkey preshared endpoint allowed_ips latest_handshake rx tx keepalive; do
  echo "  Peer VPN IP  : $allowed_ips"
  echo "  Real endpoint: $endpoint"
  if [ "$latest_handshake" = "0" ]; then
    echo "  Handshake    : ✗ NEVER — phone has not connected"
    echo "  Check        : Is sierra-demo toggle ON in WireGuard app?"
  else
    NOW=$(date +%s)
    AGO=$((NOW - latest_handshake))
    TS=$(date -r "$latest_handshake" '+%H:%M:%S' 2>/dev/null || echo "?")
    if [ $AGO -lt 180 ]; then
      echo "  Handshake    : ✅ ${AGO}s ago ($TS) — ACTIVE"
    elif [ $AGO -lt 600 ]; then
      echo "  Handshake    : ⚠️  ${AGO}s ago ($TS) — idle (normal if not browsing)"
    else
      echo "  Handshake    : ✗ ${AGO}s ago ($TS) — likely disconnected"
      echo "  Fix          : Toggle sierra-demo OFF then ON on iPhone"
    fi
  fi
  echo "  Data rx/tx   : $(echo $rx | awk '{printf "%.1f KB", $1/1024}') received / $(echo $tx | awk '{printf "%.1f MB", $1/1024/1024}') sent"
  echo ""
done
echo "  Provisioned peers: $(grep -c "AllowedIPs" infra/vpn/server/wg1-demo.conf 2>/dev/null || echo 0)"
echo ""

# ── 2. DNS chain ────────────────────────────────────────────────────────────────
echo "── 2. DNS resolution chain ─────────────────────────────────────────────"
PID_5301=$(sudo lsof -nP -iUDP:5301 2>/dev/null | awk '/dnsmasq/{print $2}' | head -1)
if [ -n "$PID_5301" ]; then
  echo "  dnsmasq on :5301 : ✅ running (PID $PID_5301)"
  NO_HOSTS=$(ps -p "$PID_5301" -o command= 2>/dev/null | grep -c "no-hosts" || echo 0)
  [ "$NO_HOSTS" -gt 0 ] && echo "  --no-hosts flag  : ✅ set (bypasses /etc/hosts)" || echo "  --no-hosts flag  : ✗ NOT set — /etc/hosts may override addresses"
else
  echo "  dnsmasq on :5301 : ✗ NOT RUNNING"
  echo "  Fix: make vpn-start"
fi

echo -n "  natsec → "
dig +short +time=2 natsec @127.0.0.1 -p 5301 2>/dev/null | head -1 && echo "  ✅ correct (10.9.0.1)" || echo "  ✗ FAILED"

echo ""

# ── 3. pf redirect ─────────────────────────────────────────────────────────────
echo "── 3. pf DNS redirect (utun9:53 → 127.0.0.1:5301) ─────────────────────"
RULE=$(sudo pfctl -a sierra-vpn-dns -s nat 2>/dev/null | grep utun9)
if [ -n "$RULE" ]; then
  echo "  ✅ $RULE"
else
  echo "  ✗ Rule NOT loaded"
  echo "  Fix: make vpn-start"
fi
echo ""

# ── 4. nginx ──────────────────────────────────────────────────────────────────
echo "── 4. nginx serving on demo gateway ────────────────────────────────────"
HTTP=$(curl -so /dev/null -w "%{http_code}" --connect-timeout 2 http://10.0.0.66/natsec/ 2>/dev/null)
[ "$HTTP" = "200" ] && echo "  http://10.0.0.66/natsec/ : ✅ HTTP 200" || echo "  http://10.0.0.66/natsec/ : ✗ HTTP $HTTP"
SN=$(grep "server_name" /usr/local/etc/nginx/servers/natsec.conf 2>/dev/null | grep -c "10\.9\.0\.1" || echo 0)
[ "$SN" -gt 0 ] && echo "  10.9.0.1 in server_name  : ✅" || echo "  10.9.0.1 in server_name  : ✗ — run: make serve-setup"
echo ""

# ── 5. nginx activity ─────────────────────────────────────────────────────────
echo "── 5. nginx — demo client requests (10.9.0.x) ─────────────────────────"
DEMO_LOG=$(grep "10\.9\." /usr/local/var/log/nginx/access.log 2>/dev/null)
TOTAL=$(echo "$DEMO_LOG" | grep -c . 2>/dev/null || echo 0)
if [ "$TOTAL" -eq 0 ]; then
  echo "  No requests yet — client has not loaded the gallery"
  echo "  Check: Is the phone on sierra-demo VPN AND opening http://natsec/natsec/?"
else
  LAST_TS=$(echo "$DEMO_LOG" | tail -1 | awk '{print $4}' | tr -d '[')
  echo "  Total requests  : $TOTAL"
  echo "  Last activity   : $LAST_TS"
  echo "  Status breakdown:"
  echo "$DEMO_LOG" | awk '{print $9}' | sort | uniq -c | sort -rn | sed 's/^/    /'
  echo "  Last 5 requests:"
  echo "$DEMO_LOG" | tail -5 | awk '{printf "    %-8s  %-6s  %s\n", $1, $9, $7}' | sed 's/\[//'
fi
echo ""

# ── 6. Troubleshooting checklist ───────────────────────────────────────────────
echo "── 6. Client can't connect — checklist ─────────────────────────────────"
echo "  □ iPhone WireGuard app: sierra-demo toggle is ON (green)"
echo "  □ Endpoint reachable: 10.0.0.66:51821 — same network as TAHOE?"
echo "  □ Try IP first: http://10.9.0.1/natsec/ (no DNS needed)"
echo "  □ If IP fails: VPN tunnel issue — toggle OFF then ON"
echo "  □ If IP works, DNS fails: run 'make vpn-start' to reload dnsmasq+pf"
echo "  □ New client? They need their own peer config: make vpn-add-demo NAME=x"
echo ""
