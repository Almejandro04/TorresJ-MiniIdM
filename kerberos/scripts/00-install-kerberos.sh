#!/usr/bin/env bash

# instalacion MIT Kerberos

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Instalacion MIT Kerberos"

require_root
require_command apt-get

print_info "Instalando KDC, kpropd, administrador y herramientas cliente"
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y krb5-kdc krb5-kpropd krb5-admin-server krb5-user

print_ok "Paquetes MIT Kerberos instalados"
