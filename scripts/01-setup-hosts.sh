#!/usr/bin/env bash

# Configuracion del host
# falta agregar al configuracion de las maquinas virtuales

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_title "Configuracion de hosts"

require_root

print_info "Plantilla del script"
print_info "/etc/hosts"

print_info "ejemplo de entradas"
echo "192.168.56.10 idm1.fis.epn.ec idm1 ldap1 kdc1 ca"
echo "192.168.56.11 idm2.fis.epn.ec idm2 ldap2 kdc2"
echo "192.168.56.12 edge.fis.epn.ec edge web ldap.fis.epn.edu.ec"
echo "192.168.56.13 client.fis.epn.ec client"

print_ok "final plantilla"