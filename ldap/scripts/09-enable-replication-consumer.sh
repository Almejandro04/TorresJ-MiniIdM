#!/usr/bin/env bash

# configuracion consumidor ldap2

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

CONSUMER_LDIF="$PROJECT_DIR/ldap/config/ldap2/replication-consumer.ldif"

print_title "Configuracion consumidor ldap2"

require_root
require_command ldapsearch
require_command ldapmodify
check_file_exists "$CONSUMER_LDIF"

if grep -q 'credentials=REPLACE_WITH_PASSWORD' "$CONSUMER_LDIF"; then
    print_error "Reemplazar credentials=REPLACE_WITH_PASSWORD antes de aplicar"
    print_error "No guardar la contrasena real en Git"
    exit 1
fi

if ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config '(olcDatabase=mdb)' olcSyncrepl | grep -q 'rid=002'; then
    print_info "Consumidor rid=002 ya configurado"
else
    print_info "Aplicando configuracion consumer"
    ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$CONSUMER_LDIF"
fi

print_ok "ldap2 configurado como consumidor de replicacion"
