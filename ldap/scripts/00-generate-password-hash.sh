#!/usr/bin/env bash

# hash SSHA LDAP

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Generacion de hash LDAP"

require_command slappasswd

read -r -s -p "Contrasena LDAP: " LDAP_PASSWORD
echo ""
read -r -s -p "Repetir contrasena LDAP: " LDAP_PASSWORD_CONFIRM
echo ""

if [ "$LDAP_PASSWORD" != "$LDAP_PASSWORD_CONFIRM" ]; then
    print_error "Las contrasenas no coinciden"
    exit 1
fi

if [ -z "$LDAP_PASSWORD" ]; then
    print_error "La contrasena no puede estar vacia"
    exit 1
fi

PASSWORD_HASH="$(slappasswd -h '{SSHA}' -s "$LDAP_PASSWORD")"
unset LDAP_PASSWORD LDAP_PASSWORD_CONFIRM

print_info "El marcador se reemplaza con esta linea:"
printf 'userPassword: %s\n' "$PASSWORD_HASH"
print_ok "Hash LDAP generado"
