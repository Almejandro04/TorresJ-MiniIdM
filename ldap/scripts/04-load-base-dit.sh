#!/usr/bin/env bash

# carga DIT LDAP

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Carga del DIT base LDAP"

LDAP_ADMIN_DN="cn=admin,dc=fis,dc=epn,dc=ec"

if grep -R -E "REPLACE_WITH|PLACEHOLDER" "$PROJECT_DIR/ldap/ldif" >/dev/null; then
    print_error "Reemplazar los placeholders de contrasena antes de cargar el DIT"
    print_info "Generar un hash con: make ldap-hash"
    exit 1
fi

print_info "Se solicitara la contrasena del administrador LDAP"

ldapadd -x -D "$LDAP_ADMIN_DN" -W -f "$PROJECT_DIR/ldap/ldif/00-base-dn.ldif"
ldapadd -x -D "$LDAP_ADMIN_DN" -W -f "$PROJECT_DIR/ldap/ldif/01-organizational-units.ldif"
ldapadd -x -D "$LDAP_ADMIN_DN" -W -f "$PROJECT_DIR/ldap/ldif/02-groups.ldif"
ldapadd -x -D "$LDAP_ADMIN_DN" -W -f "$PROJECT_DIR/ldap/ldif/03-users.ldif"
ldapadd -x -D "$LDAP_ADMIN_DN" -W -f "$PROJECT_DIR/ldap/ldif/04-service-accounts.ldif"

print_ok "DIT cargado"
