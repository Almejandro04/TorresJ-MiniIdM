#!/usr/bin/env bash

# configuracion syncprov ldap1

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

MODULE_LDIF="$PROJECT_DIR/ldap/config/ldap1/syncprov-module.ldif"
OVERLAY_LDIF="$PROJECT_DIR/ldap/config/ldap1/syncprov-overlay.ldif"
PROVIDER_LDIF="$PROJECT_DIR/ldap/config/ldap1/replication-provider.ldif"
EXPECTED_DATABASE_DN="olcDatabase={1}mdb,cn=config"

print_title "Configuracion syncprov ldap1"

require_root
require_command ldapsearch
require_command ldapmodify
require_command ldapadd
check_file_exists "$MODULE_LDIF"
check_file_exists "$OVERLAY_LDIF"
check_file_exists "$PROVIDER_LDIF"

DATABASE_DN="$(ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config '(olcDatabase=mdb)' dn | awk '/^dn: / {print $2; exit}')"

if [ "$DATABASE_DN" != "$EXPECTED_DATABASE_DN" ]; then
    print_error "Base mdb inesperada: $DATABASE_DN"
    print_error "Actualizar los LDIF syncprov para la base detectada antes de aplicar"
    exit 1
fi

if ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config '(olcModuleLoad=*syncprov*)' olcModuleLoad | grep -q syncprov; then
    print_info "Modulo syncprov ya cargado"
else
    print_info "Cargando modulo syncprov"
    ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$MODULE_LDIF"
fi

if ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b "$DATABASE_DN" '(olcOverlay=syncprov)' dn | grep -q '^dn:'; then
    print_info "Overlay syncprov ya habilitado"
else
    print_info "Habilitando overlay syncprov"
    ldapadd -Q -Y EXTERNAL -H ldapi:/// -f "$OVERLAY_LDIF"
fi

if ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b "$DATABASE_DN" olcLimits olcDbIndex | grep -q 'uid=svc-replica' && \
   ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b "$DATABASE_DN" olcDbIndex | grep -q 'entryCSN,entryUUID'; then
    print_info "Limites e indices del proveedor ya aplicados"
else
    print_info "Aplicando limites e indices del proveedor"
    ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$PROVIDER_LDIF"
fi

print_ok "ldap1 configurado como proveedor de replicacion"
