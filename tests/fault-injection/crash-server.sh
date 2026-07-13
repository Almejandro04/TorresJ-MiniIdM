#!/usr/bin/env bash

# fallo kill proceso

set -euo pipefail

PROCESS_ID="${1:-}"

if [ -z "$PROCESS_ID" ]; then
    echo "Uso: bash tests/fault-injection/crash-server.sh PID" >&2
    exit 1
fi

kill -9 "$PROCESS_ID"
echo "[OK] Proceso detenido: $PROCESS_ID"
