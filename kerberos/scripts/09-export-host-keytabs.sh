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
require_command mktemp
check_file_exists "$HOSTS_FILE"

install -d -m 0700 "$KEYTAB_DIR"

required_hosts=(
    "host/kdc1.fis.epn.ec"
    "host/idm1.fis.epn.ec"
    "host/kdc2.fis.epn.ec"
    "host/idm2.fis.epn.ec"
)

for host_name in "${required_hosts[@]}"; do
    if ! grep -Fqx -- "$host_name" "$HOSTS_FILE"; then
        print_error "Falta $host_name en $HOSTS_FILE"
        exit 1
    fi
done

idm1_keytab="$KEYTAB_DIR/idm1.keytab"
idm2_keytab="$KEYTAB_DIR/idm2.keytab"

print_info "Exportando keytab para idm1: $idm1_keytab"
export_keytab_principals "$idm1_keytab" \
    "host/kdc1.fis.epn.ec@$REALM" \
    "host/idm1.fis.epn.ec@$REALM"

print_info "Exportando keytab para idm2: $idm2_keytab"
export_keytab_principals "$idm2_keytab" \
    "host/kdc2.fis.epn.ec@$REALM" \
    "host/idm2.fis.epn.ec@$REALM"

print_ok "Keytabs host exportados"
print_info "idm1.keytab se instala en idm1 e idm2.keytab en idm2 como /etc/krb5.keytab"
