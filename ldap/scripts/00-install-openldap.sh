#!/usr/bin/env bash

# instalacion OpenLDAP

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Instalacion OpenLDAP"

require_root

print_info "Actualizando repositorios"
apt-get update

print_info "Instalando paquetes LDAP"
DEBIAN_FRONTEND=noninteractive apt-get install -y slapd ldap-utils

print_ok "OpenLDAP instalado"
