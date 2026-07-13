#!/usr/bin/env bash

# configuracion HAProxy LDAP

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Configuracion HAProxy LDAP"

require_root
require_command install
require_command haproxy
require_command systemctl

CA_CERT="$PROJECT_DIR/pki/certs/ca-root.crt"
LB_CERT="$PROJECT_DIR/pki/certs/ldap.fis.epn.edu.ec.crt"
LB_KEY="$PROJECT_DIR/pki/private/ldap.fis.epn.edu.ec.key"
HAPROXY_DIR="/etc/haproxy/miniidm"
PEM_FILE="$HAPROXY_DIR/ldap.fis.epn.edu.ec.pem"

check_file_exists "$CA_CERT"
check_file_exists "$LB_CERT"
check_file_exists "$LB_KEY"

if ! getent group haproxy >/dev/null 2>&1; then
    print_error "No existe el grupo haproxy. Instalar HAProxy primero"
    exit 1
fi

install -d -m 0750 -o root -g haproxy "$HAPROXY_DIR"
install -m 0644 -o root -g haproxy "$CA_CERT" "$HAPROXY_DIR/ca-root.crt"
cat "$LB_CERT" "$LB_KEY" > "$PEM_FILE"
chown root:haproxy "$PEM_FILE"
chmod 0640 "$PEM_FILE"
install -m 0644 -o root -g root "$PROJECT_DIR/ha/haproxy/haproxy.cfg" /etc/haproxy/haproxy.cfg

haproxy -c -f /etc/haproxy/haproxy.cfg
systemctl enable --now haproxy

print_ok "HAProxy LDAP configurado"
