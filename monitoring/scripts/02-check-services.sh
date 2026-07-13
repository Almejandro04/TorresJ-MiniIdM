#!/usr/bin/env bash

# metricas basicas MiniIdM

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

TEXTFILE_DIR="${TEXTFILE_DIR:-/var/lib/prometheus/node-exporter}"
METRICS_FILE="$TEXTFILE_DIR/miniidm.prom"
LDAP_URI="${LDAP_URI:-ldap://ldap1.fis.epn.ec}"
LDAP_BASE_DN="dc=fis,dc=epn,dc=ec"
KDC_HOST="${KDC_HOST:-kdc1.fis.epn.ec}"

print_title "Recoleccion metricas MiniIdM"

require_root
require_command systemctl
require_command date
require_command timeout

install -d -m 0755 -o root -g root "$TEXTFILE_DIR"
TEMP_FILE="$(mktemp "$TEXTFILE_DIR/miniidm.prom.XXXXXX")"
trap 'rm -f "$TEMP_FILE"' EXIT

service_metric() {
    local service_name="$1"
    local service_value=0

    if systemctl is-active --quiet "$service_name"; then
        service_value=1
    fi

    printf 'miniidm_service_up{service="%s"} %s\n' "$service_name" "$service_value" >> "$TEMP_FILE"
}

service_metric slapd
service_metric krb5-kdc
service_metric haproxy
service_metric apache2

ldap_success=0
ldap_start="$(date +%s%3N)"
if command -v ldapsearch >/dev/null 2>&1 && ldapsearch -x -LLL -H "$LDAP_URI" -b "$LDAP_BASE_DN" "(uid=jperez)" uid >/dev/null 2>&1; then
    ldap_success=1
fi
ldap_end="$(date +%s%3N)"
printf 'miniidm_ldap_query_success %s\n' "$ldap_success" >> "$TEMP_FILE"
printf 'miniidm_ldap_query_latency_milliseconds %s\n' "$((ldap_end - ldap_start))" >> "$TEMP_FILE"

kdc_success=0
if timeout 2 bash -c "</dev/tcp/$KDC_HOST/88" >/dev/null 2>&1; then
    kdc_success=1
fi
printf 'miniidm_kdc_port_up %s\n' "$kdc_success" >> "$TEMP_FILE"
printf 'miniidm_collection_timestamp_seconds %s\n' "$(date +%s)" >> "$TEMP_FILE"

chmod 0644 "$TEMP_FILE"
mv "$TEMP_FILE" "$METRICS_FILE"

print_ok "Metricas escritas en $METRICS_FILE"
