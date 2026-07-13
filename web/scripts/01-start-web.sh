#!/usr/bin/env bash

# configuracion Apache TLS Kerberos

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Configuracion servicio web"

require_root
require_command install
require_command a2enmod
require_command a2ensite
require_command systemctl

CA_CERT="$PROJECT_DIR/pki/certs/ca-root.crt"
WEB_CERT="$PROJECT_DIR/pki/certs/web.fis.epn.ec.crt"
WEB_KEY="$PROJECT_DIR/pki/private/web.fis.epn.ec.key"
WEB_KEYTAB="$PROJECT_DIR/kerberos/principals/keytabs/HTTP_web.fis.epn.ec.keytab"
APACHE_CERT_DIR="/etc/ssl/miniidm"
APACHE_KEYTAB_DIR="/etc/apache2/miniidm"

check_file_exists "$CA_CERT"
check_file_exists "$WEB_CERT"
check_file_exists "$WEB_KEY"
check_file_exists "$WEB_KEYTAB"

install -d -m 0750 -o root -g www-data "$APACHE_CERT_DIR"
install -d -m 0750 -o root -g www-data "$APACHE_KEYTAB_DIR"
install -m 0644 -o root -g www-data "$CA_CERT" "$APACHE_CERT_DIR/ca-root.crt"
install -m 0644 -o root -g www-data "$WEB_CERT" "$APACHE_CERT_DIR/web.fis.epn.ec.crt"
install -m 0640 -o root -g www-data "$WEB_KEY" "$APACHE_CERT_DIR/web.fis.epn.ec.key"
install -m 0640 -o root -g www-data "$WEB_KEYTAB" "$APACHE_KEYTAB_DIR/web.keytab"

install -d -m 0755 -o root -g root /var/www/miniidm
install -m 0644 -o root -g root "$PROJECT_DIR/web/site/index.html" /var/www/miniidm/index.html
install -m 0644 -o root -g root "$PROJECT_DIR/web/config/apache-kerberos.conf.example" /etc/apache2/sites-available/miniidm.conf

a2enmod ssl auth_gssapi
a2ensite miniidm
apache2ctl configtest
systemctl enable --now apache2

print_ok "Servicio web TLS Kerberos activo"
