#!/usr/bin/env bash

# principals servicios

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

REALM="FIS.EPN.EC"
SERVICES_FILE="$PROJECT_DIR/kerberos/principals/services.txt"
HOSTS_FILE="$PROJECT_DIR/kerberos/principals/hosts.txt"

print_title "Creacion de principals de servicio"

require_root
require_command kadmin.local
check_file_exists "$SERVICES_FILE"
check_file_exists "$HOSTS_FILE"

create_principals() {
    local principals_file="$1"
    local principal_name
    local principal

    while IFS= read -r principal_name; do
        [ -z "$principal_name" ] && continue
        case "$principal_name" in
        \#*) continue ;;
        esac

        principal="$principal_name@$REALM"
        if kadmin.local -q "getprinc $principal" >/dev/null 2>&1; then
            print_info "El principal ya existe: $principal"
            continue
        fi

        print_info "Creando principal: $principal"
        kadmin.local -q "addprinc -randkey $principal"
    done < "$principals_file"
}

create_principals "$SERVICES_FILE"
create_principals "$HOSTS_FILE"

print_ok "Principals de servicio y host procesados"
