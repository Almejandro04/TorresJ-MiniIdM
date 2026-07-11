#!/usr/bin/env bash

# Ejecucion de las pruebas generales del proyecto

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_title "Pruebas del proyecto"

print_info "Pruebas pendientes:"
echo "- LDAP search" 
echo "- LDAPS con openssl s_client"
echo "- Replicacion LDAP"
echo "- kinit kerberos"
echo "- Ticket de servicio Kerberos"
echo "- Failover de KDC"
echo "- Failover de LDAP con balanceador"
echo "- Certificado expirado"
echo "- Particion de red con iptables"
echo "- Tiempo de recuperacion"

print_ok "Listado de pruebas"