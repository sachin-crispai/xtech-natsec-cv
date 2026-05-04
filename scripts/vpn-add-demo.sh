#!/usr/bin/env bash
# Add a new demo VPN client — generates keys, updates server config, prints QR
# Usage: sudo bash scripts/vpn-add-demo.sh NAME
# e.g.:  make vpn-add-demo NAME=customer2

set -euo pipefail

[[ $EUID -ne 0 ]] && { echo "  ERROR: run with sudo"; exit 1; }
[[ -z "${1:-}" ]] && { echo "  Usage: sudo $0 NAME"; exit 1; }

NAME="$1"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_CONF="$REPO_ROOT/infra/vpn/server/wg1-demo.conf"
KEYS_DIR="$REPO_ROOT/infra/vpn/keys"
CLIENTS_DIR="$REPO_ROOT/infra/vpn/clients"
QR_DIR="$REPO_ROOT/infra/vpn/qr"

# Find next available IP in 10.9.0.x
LAST_IP=$(grep "AllowedIPs" "$SERVER_CONF" 2>/dev/null | \
  grep -oE "10\.9\.0\.[0-9]+" | sort -t. -k4 -n | tail -1)
LAST_OCTET=$(echo "${LAST_IP:-10.9.0.1}" | cut -d. -f4)
NEXT_IP="10.9.0.$((LAST_OCTET + 1))"

SERVER_PUB=$(cat "$KEYS_DIR/server.pub")
SERVER_PRIV=$(cat "$KEYS_DIR/server.key")

# Generate keypair
CLIENT_PRIV=$(wg genkey)
CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)
CLIENT_PSK=$(wg genpsk)

echo ""
echo "  Adding demo client: $NAME"
echo "  VPN IP: $NEXT_IP"
echo ""

# Save keys
echo "$CLIENT_PRIV" > "$KEYS_DIR/${NAME}-demo.key"
echo "$CLIENT_PUB"  > "$KEYS_DIR/${NAME}-demo.pub"
echo "$CLIENT_PSK"  > "$KEYS_DIR/${NAME}-demo.psk"
chmod 600 "$KEYS_DIR/${NAME}-demo.key" "$KEYS_DIR/${NAME}-demo.psk"

# Add peer to server config
cat >> "$SERVER_CONF" << EOF

# ── ${NAME} (demo client) ────────────────────────────────────────────────────
[Peer]
# ${NAME}
PublicKey    = $CLIENT_PUB
PresharedKey = $CLIENT_PSK
AllowedIPs   = $NEXT_IP/32
EOF
echo "  Added peer to wg1-demo.conf"

# Create client config
TAHOE_IP="10.0.0.66"
cat > "$CLIENTS_DIR/${NAME}-demo.conf" << EOF
# iPhone tunnel name: sierra-${NAME}-demo
# WireGuard — ${NAME} demo config (DMZ access only)

[Interface]
PrivateKey = $CLIENT_PRIV
Address    = $NEXT_IP/24
DNS        = 10.9.0.1

[Peer]
# TAHOE VPN Server (Demo DMZ gateway)
PublicKey    = $SERVER_PUB
PresharedKey = $CLIENT_PSK
Endpoint     = $TAHOE_IP:51821
AllowedIPs   = 10.9.0.0/24
PersistentKeepalive = 25
EOF
chmod 600 "$CLIENTS_DIR/${NAME}-demo.conf"
echo "  Client config: infra/vpn/clients/${NAME}-demo.conf"

# Generate QR code
if command -v qrencode >/dev/null 2>&1; then
  qrencode -t PNG -o "$QR_DIR/${NAME}-demo-qr.png" < "$CLIENTS_DIR/${NAME}-demo.conf"
  echo "  QR code: infra/vpn/qr/${NAME}-demo-qr.png"
fi

# Hot-add peer to running wg1 (no restart needed)
if wg show utun9 >/dev/null 2>&1; then
  wg set utun9 peer "$CLIENT_PUB" preshared-key "$KEYS_DIR/${NAME}-demo.psk" \
    allowed-ips "$NEXT_IP/32"
  echo "  Peer added to running utun9 (no restart needed)"
else
  echo "  utun9 not running — peer will be active on next: make vpn-start"
fi

echo ""
echo "  ╔══════════════════════════════════════════════════╗"
echo "  ║  Demo client '$NAME' created                     ║"
echo "  ╠══════════════════════════════════════════════════╣"
echo "  ║  VPN IP   : $NEXT_IP                            ║"
echo "  ║  Tunnel   : sierra-${NAME}-demo                  ║"
echo "  ╠══════════════════════════════════════════════════╣"
echo "  ║  Step 1: Scan QR or import conf to WireGuard    ║"
echo "  ║  Step 2: Connect to sierra-${NAME}-demo          ║"
echo "  ║  Step 3: Open http://natsec/natsec/             ║"
echo "  ╚══════════════════════════════════════════════════╝"
echo ""
echo "  QR code (print this for the client):"
qrencode -t ANSIUTF8 < "$CLIENTS_DIR/${NAME}-demo.conf" 2>/dev/null || \
  echo "  (brew install qrencode for terminal QR)"
echo ""
