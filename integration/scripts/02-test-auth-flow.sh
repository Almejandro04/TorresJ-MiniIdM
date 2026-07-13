#!/usr/bin/env bash

# prueba flujo LDAP Kerberos

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

USER_NAME="${1:-jperez}"
LDAP_URI="${2:-ldap://ldap1.fis.epn.ec}"
BASE_DN="dc=fis,dc=epn,dc=ec"
REALM="FIS.EPN.EC"

print_title "Prueba flujo LDAP Kerberos"

require_command ldapsearch
require_command kinit
require_command klist

print_info "Consultando identidad LDAP de $USER_NAME"
ldapsearch -x -LLL -H "$LDAP_URI" -b "$BASE_DN" "(uid=$USER_NAME)" uid cn mail

print_info "Solicitando ticket Kerberos de $USER_NAME@$REALM"
kinit "$USER_NAME@$REALM"
klist

print_ok "Flujo LDAP Kerberos validado"
