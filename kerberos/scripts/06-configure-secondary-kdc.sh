#!/usr/bin/env bash

# configuracion KDC secundario

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

REALM="FIS.EPN.EC"
DATABASE_FILE="/var/lib/krb5kdc/principal"
KEYTAB_FILE="/etc/krb5.keytab"
STASH_FILE="/etc/krb5kdc/stash"
KPROPD_ACL_FILE="/etc/krb5kdc/kpropd.acl"
SECONDARY_HOST_PRINCIPAL="host/idm2.fis.epn.ec@$REALM"

print_title "Configuracion KDC secundario"

require_root
require_command install
require_command systemctl
require_command kpropd
require_command klist
require_command ss

install -m 0644 "$PROJECT_DIR/kerberos/config/krb5.conf" /etc/krb5.conf
install -m 0644 "$PROJECT_DIR/kerberos/config/kdc.conf" /etc/krb5kdc/kdc.conf
install -m 0644 "$PROJECT_DIR/kerberos/config/kadm5.acl" /etc/krb5kdc/kadm5.acl
install -m 0644 "$PROJECT_DIR/kerberos/config/kpropd.acl" "$KPROPD_ACL_FILE"

ensure_kpropd_running() {
    systemctl enable --now krb5-kpropd

    if ! ss -ltnH 'sport = :754' | grep -q .; then
        print_error "krb5-kpropd no esta escuchando en el puerto TCP 754"
        exit 1
    fi
}

if [ -f "$DATABASE_FILE" ]; then
    print_info "La base Kerberos ya existe en idm2; no se modifico ni se reinicializo"
    require_keytab_principal "$KEYTAB_FILE" "$SECONDARY_HOST_PRINCIPAL"
    ensure_kpropd_running
    print_ok "krb5-kpropd esta habilitado y escucha en TCP 754"
    exit 0
fi

if [ ! -f "$KEYTAB_FILE" ] || [ ! -f "$STASH_FILE" ]; then
    print_error "Antes de iniciar kpropd, $KEYTAB_FILE y el stash seguro $STASH_FILE deben estar instalados"
    print_error "El stash se genera solo en idm1 y debe copiarse con propietario root y modo 0600"
    exit 1
fi

chown root:root "$KEYTAB_FILE" "$STASH_FILE"
chmod 0600 "$KEYTAB_FILE" "$STASH_FILE"
require_keytab_principal "$KEYTAB_FILE" "$SECONDARY_HOST_PRINCIPAL"
check_file_exists "$KPROPD_ACL_FILE"

print_info "Manteniendo krb5-kdc detenido hasta recibir la primera propagacion"
systemctl stop krb5-kdc
ensure_kpropd_running

print_info "kpropd escucha en TCP 754; reciba ahora la primera base desde idm1"
print_info "Después de verificar la base con kadmin.local, se habilita krb5-kdc"
print_ok "KDC secundario preparado"
