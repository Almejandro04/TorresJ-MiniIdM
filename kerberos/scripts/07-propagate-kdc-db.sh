#!/usr/bin/env bash

# propagacion base Kerberos

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

SECONDARY_HOST="${1:-kdc2.fis.epn.ec}"
DATABASE_FILE="/var/lib/krb5kdc/principal"

print_title "Propagacion de base Kerberos"

require_root
require_command kprop
check_file_exists "$DATABASE_FILE"

print_info "Propagando base hacia $SECONDARY_HOST"
kprop -f "$DATABASE_FILE" "$SECONDARY_HOST"

print_ok "Base Kerberos propagada"
