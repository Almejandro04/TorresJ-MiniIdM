#!/usr/bin/env bash

# fallo particion red

set -euo pipefail

REMOTE_HOST="${1:-}"
REMOTE_PORT="${2:-}"

if [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_PORT" ]; then
    echo "Uso: sudo bash tests/fault-injection/network-partition.sh HOST PUERTO" >&2
    exit 1
fi

iptables -I OUTPUT -p tcp -d "$REMOTE_HOST" --dport "$REMOTE_PORT" -j DROP
iptables -I INPUT -p tcp -s "$REMOTE_HOST" --sport "$REMOTE_PORT" -j DROP
echo "[CORRECTO] Particion aplicada a $REMOTE_HOST:$REMOTE_PORT"
