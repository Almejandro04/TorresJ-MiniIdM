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
STASH_FILE="/etc/krb5kdc/stash"
KEYTAB_FILE="/etc/krb5.keytab"
DUMP_FILE="/var/lib/krb5kdc/slave_datatrans"
REALM="FIS.EPN.EC"
HOST_PRINCIPAL="host/idm1.fis.epn.ec@$REALM"

print_title "Propagacion de base Kerberos"

require_root
require_command kprop
require_command kdb5_util
require_command klist
require_command getent
check_file_exists "$DATABASE_FILE"
check_file_exists "$STASH_FILE"
check_file_exists "$KEYTAB_FILE"

if ! getent hosts "$SECONDARY_HOST" >/dev/null 2>&1; then
    print_error "No se resuelve el destino: $SECONDARY_HOST"
    exit 1
fi

require_keytab_principal "$KEYTAB_FILE" "$HOST_PRINCIPAL"

if [ "$CHECK_ONLY" = true ]; then
    print_ok "Requisitos locales de propagacion correctos"
    print_info "Confirmar en idm2 el stash, host/idm2.fis.epn.ec y krb5-kpropd en TCP 754"
    exit 0
fi

umask 077
print_info "Generando dump de la base Kerberos"
kdb5_util -r "$REALM" -d "$DATABASE_FILE" -sf "$STASH_FILE" dump "$DUMP_FILE"
chmod 0600 "$DUMP_FILE"
check_file_nonempty "$DUMP_FILE"

print_info "Propagando dump hacia $SECONDARY_HOST"
kprop -r "$REALM" -s "$KEYTAB_FILE" -f "$DUMP_FILE" "$SECONDARY_HOST"

print_ok "Propagacion de la base Kerberos hacia $SECONDARY_HOST completada correctamente"
