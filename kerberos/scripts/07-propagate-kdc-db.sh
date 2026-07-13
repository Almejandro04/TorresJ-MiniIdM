#!/usr/bin/env bash

# propagacion base Kerberos

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

CHECK_ONLY=false
if [ "${1:-}" = "--check" ]; then
    CHECK_ONLY=true
    shift
fi

SECONDARY_HOST="${1:-kdc2.fis.epn.ec}"
DATABASE_FILE="/var/lib/krb5kdc/principal"
HOST_PRINCIPAL="host/kdc1.fis.epn.ec@FIS.EPN.EC"

print_title "Propagacion de base Kerberos"

require_root
require_command kprop
require_command klist
require_command getent
check_file_exists "$DATABASE_FILE"

if ! getent hosts "$SECONDARY_HOST" >/dev/null 2>&1; then
    print_error "No se resuelve el destino: $SECONDARY_HOST"
    exit 1
fi

if ! klist -k /etc/krb5.keytab 2>/dev/null | grep -q "$HOST_PRINCIPAL"; then
    print_error "Falta $HOST_PRINCIPAL en /etc/krb5.keytab"
    print_error "Exportar keytabs host y copiar el keytab correcto a cada KDC"
    exit 1
fi

if [ "$CHECK_ONLY" = true ]; then
    print_ok "Requisitos locales de propagacion correctos"
    print_info "Confirmar en kdc2 la instalacion de host_kdc2.fis.epn.ec.keytab"
    exit 0
fi

print_info "Propagando base hacia $SECONDARY_HOST"
kprop -f "$DATABASE_FILE" "$SECONDARY_HOST"

print_ok "Base Kerberos propagada"
