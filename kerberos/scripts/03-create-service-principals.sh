#!/usr/bin/env bash

# principals servicios

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

REALM="FIS.EPN.EC"
SERVICES_FILE="$PROJECT_DIR/kerberos/principals/services.txt"

print_title "Creacion de principals de servicio"

require_root
require_command kadmin.local
check_file_exists "$SERVICES_FILE"

while IFS= read -r service_name; do
    [ -z "$service_name" ] && continue
    case "$service_name" in
        \#*) continue ;;
    esac

    principal="$service_name@$REALM"
    if kadmin.local -q "getprinc $principal" >/dev/null 2>&1; then
        print_info "El principal ya existe: $principal"
        continue
    fi

    print_info "Creando principal de servicio: $principal"
    kadmin.local -q "addprinc -randkey $principal"
done < "$SERVICES_FILE"

print_ok "Principals de servicio procesados"
