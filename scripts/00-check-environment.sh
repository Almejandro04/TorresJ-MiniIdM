#!/usr/bin/env bash

# verificacion entorno

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

print_title "Verificacion del entorno"

require_command bash
require_command make
require_command git
require_command openssl
require_command hostname
require_command ip
require_command systemctl

print_ok "Herramientas basicas encontradas"

print_info "Sistema: "
uname -a

print_info "Nombre de host actual: "
hostname

print_info "Direcciones IP:"
ip addr show | grep "inet " || true

print_ok "Verificacion finalizada"
