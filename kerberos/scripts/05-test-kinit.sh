#!/usr/bin/env bash

# prueba kinit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

REALM="FIS.EPN.EC"
USER_NAME="${1:-jperez}"

print_title "Prueba kinit"

require_command kinit
require_command klist

print_info "Solicitando ticket para $USER_NAME@$REALM"
kinit "$USER_NAME@$REALM"
klist

print_ok "Ticket Kerberos obtenido"
