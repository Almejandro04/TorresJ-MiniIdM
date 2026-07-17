#!/usr/bin/env bash

# configuracion DIT slapd

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

BASE_DN="dc=fis,dc=epn,dc=ec"
ADMIN_DN="cn=admin,$BASE_DN"

print_title "Configuracion base de slapd"

if [ "$#" -eq 0 ]; then
    print_info "Modo vista previa"
    print_info "Base DN: $BASE_DN"
    print_info "Administrador: $ADMIN_DN"
    print_info "La ejecución con --apply se realiza solo en una VM de laboratorio nueva"
    exit 0
fi

if [ "$#" -ne 1 ] || [ "$1" != "--apply" ]; then
    print_error "Uso: bash ldap/scripts/01-configure-slapd.sh [--apply]"
    exit 1
fi

require_root
require_command ldapsearch
require_command ldapmodify
require_command slappasswd

LDAP_DATABASE_DN="$(ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config '(olcDatabase=mdb)' dn | awk '/^dn: / {print $2; exit}')"

if [ -z "$LDAP_DATABASE_DN" ]; then
    print_error "No se encontro una base mdb en cn=config"
    exit 1
fi

read -r -s -p "Contrasena para $ADMIN_DN: " LDAP_ADMIN_PASSWORD
echo ""

if [ -z "$LDAP_ADMIN_PASSWORD" ]; then
    print_error "La contrasena no puede estar vacia"
    exit 1
fi

ADMIN_HASH="$(slappasswd -h '{SSHA}' -s "$LDAP_ADMIN_PASSWORD")"
unset LDAP_ADMIN_PASSWORD
CONFIG_LDIF="$(mktemp)"
trap 'rm -f "$CONFIG_LDIF"' EXIT

cat > "$CONFIG_LDIF" <<EOF
dn: $LDAP_DATABASE_DN
changetype: modify
replace: olcSuffix
olcSuffix: $BASE_DN
-
replace: olcRootDN
olcRootDN: $ADMIN_DN
-
replace: olcRootPW
olcRootPW: $ADMIN_HASH
-
replace: olcDbIndex
olcDbIndex: objectClass eq
olcDbIndex: uid eq
olcDbIndex: cn,sn eq
olcDbIndex: entryCSN,entryUUID eq
EOF

print_info "Configurando base: $LDAP_DATABASE_DN"
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$CONFIG_LDIF"

print_ok "Configuracion base de slapd aplicada"
print_info "El DIT se carga después con: make ldap-load"
