#!/usr/bin/env bash

# inicializacion realm Kerberos

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

REALM="FIS.EPN.EC"
SECONDARY_HOSTNAME="idm2"
SECONDARY_FQDN="idm2.fis.epn.ec"

print_title "Inicializacion del realm Kerberos"

require_root
require_command install
require_command kdb5_util
require_command kadmin.local
require_command hostname

local_hostname="$(hostname -s)"
local_fqdn="$(hostname -f 2>/dev/null || true)"
if [ "$local_hostname" = "$SECONDARY_HOSTNAME" ] || [ "$local_hostname" = "kdc2" ] || [ "$local_fqdn" = "$SECONDARY_FQDN" ]; then
    print_error "01-init-realm.sh no se ejecuta en idm2: el KDC secundario recibe la base mediante kprop"
    exit 1
fi

install -m 0644 "$PROJECT_DIR/kerberos/config/krb5.conf" /etc/krb5.conf
install -m 0644 "$PROJECT_DIR/kerberos/config/kdc.conf" /etc/krb5kdc/kdc.conf
install -m 0644 "$PROJECT_DIR/kerberos/config/kadm5.acl" /etc/krb5kdc/kadm5.acl

if [ -f /var/lib/krb5kdc/principal ]; then
    print_error "La base Kerberos ya existe. No se reemplazo"
    exit 1
fi

print_info "Se solicitara la contrasena maestra del realm"
kdb5_util create -s -r "$REALM"

print_info "Creando principal administrativo admin/admin"
kadmin.local -q "addprinc admin/admin"

systemctl enable --now krb5-kdc krb5-admin-server

print_ok "Realm $REALM inicializado"
