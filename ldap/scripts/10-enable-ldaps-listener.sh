#!/usr/bin/env bash

# listener LDAPS slapd

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

SLAPD_DEFAULTS="/etc/default/slapd"
SLAPD_SERVICES='SLAPD_SERVICES="ldap:/// ldapi:/// ldaps:///"'

print_title "Listener LDAPS slapd"

require_root
require_command sed
require_command systemctl

if [ ! -f "$SLAPD_DEFAULTS" ]; then
    print_error "No existe $SLAPD_DEFAULTS"
    exit 1
fi

if grep -q '^SLAPD_SERVICES=' "$SLAPD_DEFAULTS"; then
    sed -i "s|^SLAPD_SERVICES=.*|$SLAPD_SERVICES|" "$SLAPD_DEFAULTS"
else
    printf '%s\n' "$SLAPD_SERVICES" >> "$SLAPD_DEFAULTS"
fi

systemctl restart slapd

print_ok "Listener LDAPS habilitado"
