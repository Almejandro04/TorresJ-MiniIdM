#!/usr/bin/env bash

# configuracion LDAPS

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Configuracion LDAPS"

require_root

if [ "$#" -ne 1 ]; then
    print_error "Uso: bash ldap/scripts/02-enable-ldaps.sh ldap1|ldap2"
    exit 1
fi

LDAP_NODE="$1"

if [ "$LDAP_NODE" != "ldap1" ] && [ "$LDAP_NODE" != "ldap2" ]; then
    print_error "Nodo invalido. Se utiliza ldap1 o ldap2"
    exit 1
fi

TLS_FILE="$PROJECT_DIR/ldap/config/$LDAP_NODE/tls.ldif"

check_file_exists "$TLS_FILE"

print_info "Configurando TLS para $LDAP_NODE"
ldapmodify -Y EXTERNAL -H ldapi:/// -f "$TLS_FILE"

print_ok "Configuracion TLS aplicada"
