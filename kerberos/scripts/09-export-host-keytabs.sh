#!/usr/bin/env bash

# exportacion keytabs host

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

REALM="FIS.EPN.EC"
HOSTS_FILE="$PROJECT_DIR/kerberos/principals/hosts.txt"
KEYTAB_DIR="$PROJECT_DIR/kerberos/principals/keytabs"

print_title "Exportacion keytabs host"

require_root
require_command kadmin.local
check_file_exists "$HOSTS_FILE"

install -d -m 0700 "$KEYTAB_DIR"

while IFS= read -r host_name; do
    [ -z "$host_name" ] && continue
    case "$host_name" in
        \#*) continue ;;
    esac

    safe_name="${host_name//\//_}"
    keytab_file="$KEYTAB_DIR/$safe_name.keytab"
    principal="$host_name@$REALM"

    print_info "Exportando keytab: $keytab_file"
    kadmin.local -q "ktadd -k $keytab_file $principal"
    chmod 0600 "$keytab_file"
done < "$HOSTS_FILE"

print_ok "Keytabs host exportados"
print_info "Instalar host_kdc1 en kdc1 y host_kdc2 en kdc2 como /etc/krb5.keytab"
