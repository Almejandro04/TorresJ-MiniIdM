#!/usr/bin/env bash

# prueba failover KDC

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

REALM="FIS.EPN.EC"
USER_NAME="${1:-jperez}"
SERVICE_PRINCIPAL="${2:-ldap/ldap2.fis.epn.ec}"

print_title "Prueba failover KDC"

require_command kdestroy
require_command kinit
require_command klist
require_command kvno
require_command date

print_info "Detener krb5-kdc en kdc1 antes de ejecutar esta prueba"
start_time="$(date +%s%3N)"
kdestroy || true
kinit "$USER_NAME@$REALM"
end_time="$(date +%s%3N)"

klist
print_info "Solicitando ticket de servicio para $SERVICE_PRINCIPAL@$REALM"
kvno "$SERVICE_PRINCIPAL@$REALM"
klist
print_info "Tiempo de autenticacion: $((end_time - start_time)) ms"
print_ok "Prueba failover KDC completada"
