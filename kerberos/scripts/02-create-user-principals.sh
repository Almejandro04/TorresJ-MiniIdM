#!/usr/bin/env bash

# principals usuarios

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

REALM="FIS.EPN.EC"
USERS_FILE="$PROJECT_DIR/kerberos/principals/users.txt"

print_title "Creacion de principals de usuario"

require_root
require_command kadmin.local
check_file_exists "$USERS_FILE"

while IFS= read -r user_name; do
    [ -z "$user_name" ] && continue
    case "$user_name" in
        \#*) continue ;;
    esac

    principal="$user_name@$REALM"
    if kadmin.local -q "getprinc $principal" >/dev/null 2>&1; then
        print_info "El principal ya existe: $principal"
        continue
    fi

    print_info "Definir contrasena para: $principal"
    kadmin.local -q "addprinc $principal"
done < "$USERS_FILE"

print_ok "Principals de usuario procesados"
