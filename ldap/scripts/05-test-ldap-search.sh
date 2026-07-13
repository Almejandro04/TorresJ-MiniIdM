#!/usr/bin/env bash

# prueba consulta LDAP

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Prueba LDAP search"

LDAP_URI="${1:-ldap://localhost}"
BASE_DN="dc=fis,dc=epn,dc=ec"

print_info "URI LDAP: $LDAP_URI"
print_info "Base DN: $BASE_DN"

ldapsearch -x -H "$LDAP_URI" -b "$BASE_DN" "(objectClass=*)"

print_ok "Fin consulta LDAP"
