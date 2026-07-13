#!/usr/bin/env bash

# exportacion keytabs servicios

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

REALM="FIS.EPN.EC"
SERVICES_FILE="$PROJECT_DIR/kerberos/principals/services.txt"
KEYTAB_DIR="$PROJECT_DIR/kerberos/principals/keytabs"

print_title "Exportacion de keytabs"

require_root
require_command kadmin.local
check_file_exists "$SERVICES_FILE"

install -d -m 0700 "$KEYTAB_DIR"

while IFS= read -r service_name; do
    [ -z "$service_name" ] && continue
    case "$service_name" in
        \#*) continue ;;
    esac

    safe_name="${service_name//\//_}"
    keytab_file="$KEYTAB_DIR/$safe_name.keytab"
    principal="$service_name@$REALM"

    print_info "Exportando keytab: $keytab_file"
    kadmin.local -q "ktadd -k $keytab_file $principal"
    chmod 0600 "$keytab_file"
done < "$SERVICES_FILE"

print_ok "Keytabs exportados"
