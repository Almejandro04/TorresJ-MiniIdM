#!/usr/bin/env bash

# configuracion hosts

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_title "Configuracion de hosts"

require_root

print_info "Plantilla del script"
print_info "/etc/hosts"

print_info "ejemplo de entradas"
echo "192.168.56.10 idm1.fis.epn.ec idm1 ldap1.fis.epn.ec ldap1 kdc1.fis.epn.ec kdc1 ca.fis.epn.ec ca ldap.fis.epn.edu.ec web.fis.epn.ec"
echo "192.168.56.11 idm2.fis.epn.ec idm2 ldap2.fis.epn.ec ldap2 kdc2.fis.epn.ec kdc2"

print_ok "final plantilla"
