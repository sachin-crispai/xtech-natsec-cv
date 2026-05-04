#!/usr/bin/env bash
# Start WireGuard VPN interfaces on TAHOE rig
# Usage: sudo bash scripts/vpn-start.sh [--stop]

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

[[ $EUID -ne 0 ]] && { echo "  ERROR: run with sudo"; exit 1; }

if [[ "${1:-}" == "--stop" ]]; then
  echo "  Stopping VPN interfaces..."
  wg-quick down "$REPO_ROOT/infra/vpn/server/wg0-operators.conf" 2>/dev/null || true
  wg-quick down "$REPO_ROOT/infra/vpn/server/wg1-demo.conf"      2>/dev/null || true
  echo "  VPN stopped."
  exit 0
fi

echo ""
echo "  Starting SIERRA VPN"
echo "  ─────────────────────────────────────"
echo "  [1/2] Operator network (wg0 · port 51820)..."
wg-quick up "$REPO_ROOT/infra/vpn/server/wg0-operators.conf"
echo "        KEN    → 10.8.0.2"
echo "        SACHIN → 10.8.0.3"

echo "  [2/2] Demo DMZ network (wg1 · port 51821)..."
wg-quick up "$REPO_ROOT/infra/vpn/server/wg1-demo.conf"
echo "        DEMO   → 10.9.0.2"

  echo "  [3/3] Starting VPN DNS (natsec, tahoe, mamba → 10.0.0.66)..."

# Kill any existing instance
pkill -f "dnsmasq.*sierra" 2>/dev/null || true
sleep 0.5

# Deploy DNS config — listens on 127.0.0.1:5300
mkdir -p /usr/local/etc/dnsmasq.d
cp "$REPO_ROOT/infra/dnsmasq/sierra.conf" /usr/local/etc/dnsmasq.d/sierra.conf
/usr/local/sbin/dnsmasq \
  --conf-file=/usr/local/etc/dnsmasq.d/sierra.conf \
  --pid-file=/tmp/dnsmasq-sierra.pid
echo "     dnsmasq on 127.0.0.1:5300 (PID: $(cat /tmp/dnsmasq-sierra.pid 2>/dev/null || echo '?'))"

# Load pf redirect: VPN client DNS queries (10.8.0.1:53) → dnsmasq:5300
cp "$REPO_ROOT/infra/vpn/pf-dns.conf" /etc/pf.anchors/sierra-vpn-dns
pfctl -f /etc/pf.conf 2>/dev/null || true
pfctl -a sierra-vpn-dns -f /etc/pf.anchors/sierra-vpn-dns 2>/dev/null && \
  echo "     pf DNS redirect active (utun8:53 → 127.0.0.1:5300)"

echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║  SIERRA VPN is LIVE                             ║"
echo "  ╠══════════════════════════════════════════════════╣"
echo "  ║  Operator gateway  : 10.8.0.1  port 51820      ║"
echo "  ║    KEN             : 10.8.0.2                  ║"
echo "  ║    SACHIN (mamba)  : 10.8.0.3                  ║"
echo "  ╠══════════════════════════════════════════════════╣"
echo "  ║  Demo DMZ gateway  : 10.9.0.1  port 51821      ║"
echo "  ║    DEMO            : 10.9.0.2                  ║"
echo "  ╠══════════════════════════════════════════════════╣"
echo "  ║  QR codes to share with operators:              ║"
echo "  ║    infra/vpn/qr/ken-qr.png                     ║"
echo "  ║    infra/vpn/qr/sachin-qr.png                  ║"
echo "  ║    infra/vpn/qr/demo-qr.png                    ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""
wg show
