#!/usr/bin/env bash

# prueba lectura replicacion

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Prueba replicacion LDAP"

BASE_DN="dc=fis,dc=epn,dc=ec"

print_info "Consultando LDAP master ldap1"
ldapsearch -x -H ldap://ldap1.fis.epn.ec -b "$BASE_DN" "(uid=jperez)" uid cn mail

print_info "Consultando LDAP replica ldap2"
ldapsearch -x -H ldap://ldap2.fis.epn.ec -b "$BASE_DN" "(uid=jperez)" uid cn mail

print_ok "Fin prueba replica"
