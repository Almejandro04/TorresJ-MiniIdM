#!/usr/bin/env bash

# prueba Kerberos web

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

USER_NAME="${1:-jperez}"
WEB_URL="${2:-https://web.fis.epn.ec/}"
CA_CERT="$PROJECT_DIR/pki/certs/ca-root.crt"
REALM="FIS.EPN.EC"

print_title "Prueba Kerberos web"

require_command kinit
require_command curl
check_file_exists "$CA_CERT"

kinit "$USER_NAME@$REALM"
curl --fail --negotiate -u : --cacert "$CA_CERT" "$WEB_URL"

print_ok "Acceso web con Kerberos verificado"
