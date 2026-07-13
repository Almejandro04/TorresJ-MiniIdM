#!/usr/bin/env bash

# restauracion red

set -euo pipefail

REMOTE_HOST="${1:-}"
REMOTE_PORT="${2:-}"

if [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_PORT" ]; then
    echo "Uso: sudo bash tests/fault-injection/restore-network.sh HOST PUERTO" >&2
    exit 1
fi

iptables -D OUTPUT -p tcp -d "$REMOTE_HOST" --dport "$REMOTE_PORT" -j DROP || true
iptables -D INPUT -p tcp -s "$REMOTE_HOST" --sport "$REMOTE_PORT" -j DROP || true
echo "[OK] Particion restaurada para $REMOTE_HOST:$REMOTE_PORT"
