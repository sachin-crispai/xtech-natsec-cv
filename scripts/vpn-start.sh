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

# Fix permissions — wg-quick warns on world-readable configs
chmod 600 "$REPO_ROOT/infra/vpn/server/wg0-operators.conf" \
           "$REPO_ROOT/infra/vpn/server/wg1-demo.conf" 2>/dev/null || true

echo "  [1/2] Operator network (wg0 · port 51820)..."
if wg show utun8 >/dev/null 2>&1; then
  echo "        already running — skipping (use make vpn-stop first to restart)"
else
  wg-quick up "$REPO_ROOT/infra/vpn/server/wg0-operators.conf"
fi
echo "        KEN    → 10.8.0.2"
echo "        SACHIN → 10.8.0.3"

echo "  [2/2] Demo DMZ network (wg1 · port 51821)..."
if wg show utun9 >/dev/null 2>&1; then
  echo "        already running — skipping"
else
  wg-quick up "$REPO_ROOT/infra/vpn/server/wg1-demo.conf"
fi
echo "        DEMO   → 10.9.0.2"

  echo "  [3/3] Starting VPN DNS..."

  # Kill any existing instances
  pkill -f "dnsmasq.*sierra" 2>/dev/null || true
  pkill -f "dnsmasq.*demo.pid" 2>/dev/null || true
  sleep 0.5

  # Operator DNS (port 5300) — natsec → 10.0.0.66
  mkdir -p /usr/local/etc/dnsmasq.d
  cp "$REPO_ROOT/infra/dnsmasq/sierra.conf" /usr/local/etc/dnsmasq.d/sierra.conf
  /usr/local/sbin/dnsmasq \
    --conf-file=/usr/local/etc/dnsmasq.d/sierra.conf \
    --pid-file=/tmp/dnsmasq-sierra.pid
  echo "     operator DNS on :5300 — natsec → 10.0.0.66 (PID $(cat /tmp/dnsmasq-sierra.pid 2>/dev/null))"

  # Demo DMZ DNS (port 5301) — natsec → 10.9.0.1 (in demo AllowedIPs)
  # --no-hosts: /etc/hosts has natsec=10.0.0.66 which must be ignored for demo
  /usr/local/sbin/dnsmasq \
    --port=53 \
    --listen-address=10.9.0.1 \
    --no-hosts --no-resolv \
    --address=/natsec/10.9.0.1 --address=/natsec.sierra/10.9.0.1 \
    --address=/tahoe/10.9.0.1 --address=/gallery.sierra/10.9.0.1 --address=/mamba/10.9.0.1 \
    --server=8.8.8.8 \
    --pid-file=/tmp/dnsmasq-demo.pid
  echo "     demo DMZ DNS on :5301  — natsec → 10.9.0.1  (PID $(cat /tmp/dnsmasq-demo.pid 2>/dev/null))"

  # Load pf redirects: utun8:53 → 5300 (operators), utun9:53 → 5301 (demo)
  cp "$REPO_ROOT/infra/vpn/pf-dns.conf" /etc/pf.anchors/sierra-vpn-dns
  pfctl -f /etc/pf.conf 2>/dev/null || true
  pfctl -a sierra-vpn-dns -f /etc/pf.anchors/sierra-vpn-dns 2>/dev/null && \
    echo "     pf: utun8:53→5300 (operators)  utun9:53→5301 (demo)"

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
echo "  ║  DEMO access (connect sierra-demo first):       ║"
echo "  ║    via DNS : http://natsec/natsec/              ║"
echo "  ║    via IP  : http://10.9.0.1/natsec/            ║"
echo "  ║                                                 ║"
echo "  ║  Troubleshooting:                               ║"
echo "  ║  IP works, DNS fails  → DNS/pf routing issue   ║"
echo "  ║  IP also fails        → VPN tunnel issue       ║"
echo "  ╠══════════════════════════════════════════════════╣"
echo "  ║  QR codes to share with operators:              ║"
echo "  ║    infra/vpn/qr/ken-qr.png                     ║"
echo "  ║    infra/vpn/qr/sachin-qr.png                  ║"
echo "  ║    infra/vpn/qr/demo-qr.png                    ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""
wg show
