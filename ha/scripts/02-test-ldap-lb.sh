#!/usr/bin/env bash

# prueba balanceador LDAP

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

LDAP_URI="${1:-ldaps://ldap.fis.epn.edu.ec}"
BASE_DN="dc=fis,dc=epn,dc=ec"
CA_CERT="$PROJECT_DIR/pki/certs/ca-root.crt"

print_title "Prueba balanceador LDAP"

require_command ldapsearch
check_file_exists "$CA_CERT"

ldapsearch -x -H "$LDAP_URI" -o "TLS_CACERT=$CA_CERT" -b "$BASE_DN" "(uid=jperez)" uid cn mail

print_ok "Consulta LDAP por balanceador completada"
