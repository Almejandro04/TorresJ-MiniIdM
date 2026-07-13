#!/usr/bin/env bash

# instalacion Apache GSSAPI

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Instalacion servicio web"

require_root
require_command apt-get

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 libapache2-mod-auth-gssapi curl

print_ok "Apache y modulo GSSAPI instalados"
