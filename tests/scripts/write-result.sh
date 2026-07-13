#!/usr/bin/env bash

# registro resultado CSV

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESULTS_DIR="$PROJECT_DIR/results/raw"
RESULTS_FILE="$RESULTS_DIR/test-results.csv"

if [ "$#" -ne 5 ]; then
    echo "Uso: bash tests/scripts/write-result.sh TEST TARGET STATUS LATENCY_MS NOTES" >&2
    exit 1
fi

TEST_NAME="$1"
TARGET="$2"
STATUS="$3"
LATENCY_MS="$4"
NOTES="${5//\"/\"\"}"

mkdir -p "$RESULTS_DIR"

if [ ! -f "$RESULTS_FILE" ]; then
    printf '%s\n' 'timestamp,test_name,target,status,latency_ms,notes' > "$RESULTS_FILE"
fi

printf '%s,%s,%s,%s,%s,"%s"\n' "$(date -Iseconds)" "$TEST_NAME" "$TARGET" "$STATUS" "$LATENCY_MS" "$NOTES" >> "$RESULTS_FILE"
