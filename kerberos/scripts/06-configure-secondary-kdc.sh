#!/usr/bin/env bash

# configuracion KDC secundario

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Configuracion KDC secundario"

require_root
require_command install

install -m 0644 "$PROJECT_DIR/kerberos/config/krb5.conf" /etc/krb5.conf
install -m 0644 "$PROJECT_DIR/kerberos/config/kdc.conf" /etc/krb5kdc/kdc.conf
install -m 0644 "$PROJECT_DIR/kerberos/config/kadm5.acl" /etc/krb5kdc/kadm5.acl
install -m 0644 "$PROJECT_DIR/kerberos/config/kpropd.acl" /etc/krb5kdc/kpropd.acl

systemctl enable --now kpropd

print_info "Agregar host/kdc2.fis.epn.ec al KDC primario y copiar su keytab al secundario"
print_info "La primera base debe llegar con kerberos/scripts/07-propagate-kdc-db.sh"
print_ok "KDC secundario preparado"
