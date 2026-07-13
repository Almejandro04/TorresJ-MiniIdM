#!/usr/bin/env bash

# pruebas generales

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_title "Pruebas del proyecto"

if [ "${1:-list}" = "run" ]; then
    bash "$SCRIPT_DIR/../tests/scripts/run-tests.sh" run
    print_ok "Pruebas automaticas completadas"
    exit 0
fi

bash "$SCRIPT_DIR/../tests/scripts/run-tests.sh" list
print_ok "Listado de pruebas"
