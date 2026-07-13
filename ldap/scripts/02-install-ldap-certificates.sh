#!/usr/bin/env bash

# certificados LDAP

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Instalacion de certificados LDAP"

require_root
require_command install

if [ "$#" -ne 1 ]; then
    print_error "Uso: bash ldap/scripts/02-install-ldap-certificates.sh ldap1|ldap2"
    exit 1
fi

LDAP_NODE="$1"

if [ "$LDAP_NODE" != "ldap1" ] && [ "$LDAP_NODE" != "ldap2" ]; then
    print_error "Nodo invalido. Usar ldap1 o ldap2"
    exit 1
fi

CA_CERT="$PROJECT_DIR/pki/certs/ca-root.crt"
SERVER_CERT="$PROJECT_DIR/pki/certs/$LDAP_NODE.fis.epn.ec.crt"
SERVER_KEY="$PROJECT_DIR/pki/private/$LDAP_NODE.fis.epn.ec.key"
TARGET_DIR="/etc/ssl/miniidm"

check_file_exists "$CA_CERT"
check_file_exists "$SERVER_CERT"
check_file_exists "$SERVER_KEY"

if ! getent group openldap >/dev/null 2>&1; then
    print_error "No existe el grupo openldap. Instalar OpenLDAP primero"
    exit 1
fi

install -d -m 0750 -o root -g openldap "$TARGET_DIR"
install -m 0644 -o root -g openldap "$CA_CERT" "$TARGET_DIR/ca-root.crt"
install -m 0644 -o root -g openldap "$SERVER_CERT" "$TARGET_DIR/$LDAP_NODE.fis.epn.ec.crt"
install -m 0640 -o root -g openldap "$SERVER_KEY" "$TARGET_DIR/$LDAP_NODE.fis.epn.ec.key"

print_ok "Certificados instalados en $TARGET_DIR"
