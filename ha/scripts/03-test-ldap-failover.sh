#!/usr/bin/env bash

# prueba failover LDAP

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

LDAP_URI="${1:-ldaps://ldap.fis.epn.edu.ec:1636}"
BASE_DN="dc=fis,dc=epn,dc=ec"
CA_CERT="$PROJECT_DIR/pki/certs/ca-root.crt"

print_title "Prueba failover LDAP"

require_command ldapsearch
check_file_exists "$CA_CERT"

print_info "Detener slapd en ldap1 antes de ejecutar esta prueba"
ldapsearch -x -H "$LDAP_URI" -o "TLS_CACERT=$CA_CERT" -b "$BASE_DN" "(uid=jperez)" uid cn mail

print_ok "Lectura LDAP disponible despues del fallo"
