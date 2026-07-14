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
LDAP_TIMEOUT_SECONDS="${LDAP_TIMEOUT_SECONDS:-2}"

print_title "Recoleccion metricas MiniIdM"

require_root
require_command systemctl
require_command date
require_command timeout
require_command awk

case "$LDAP_TIMEOUT_SECONDS" in
    ''|*[!0-9]*)
        print_error "LDAP_TIMEOUT_SECONDS debe ser un entero positivo"
        exit 1
        ;;
esac

if [ "$LDAP_TIMEOUT_SECONDS" -eq 0 ]; then
    print_error "LDAP_TIMEOUT_SECONDS debe ser mayor que cero"
    exit 1
fi

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

monotonic_milliseconds() {
    if [ ! -r /proc/uptime ]; then
        print_error "No se encontro un reloj monotono en /proc/uptime"
        exit 1
    fi

    awk '{ printf "%.0f", $1 * 1000 }' /proc/uptime
}

ldap_success=0
ldap_timeout_milliseconds="$((LDAP_TIMEOUT_SECONDS * 1000))"
ldap_start="$(monotonic_milliseconds)"
ldap_exit_status=127

if command -v ldapsearch >/dev/null 2>&1; then
    if timeout "$LDAP_TIMEOUT_SECONDS" ldapsearch -x -LLL -H "$LDAP_URI" -b "$LDAP_BASE_DN" "(uid=jperez)" uid >/dev/null 2>&1; then
        ldap_success=1
        ldap_exit_status=0
    else
        ldap_exit_status=$?
    fi
fi
ldap_end="$(monotonic_milliseconds)"
ldap_latency_milliseconds="$((ldap_end - ldap_start))"

if [ "$ldap_exit_status" -eq 124 ] || [ "$ldap_latency_milliseconds" -lt 0 ] || [ "$ldap_latency_milliseconds" -gt "$ldap_timeout_milliseconds" ]; then
    ldap_success=0
    ldap_latency_milliseconds="$ldap_timeout_milliseconds"
fi

printf 'miniidm_ldap_query_success %s\n' "$ldap_success" >> "$TEMP_FILE"
printf 'miniidm_ldap_query_latency_milliseconds %s\n' "$ldap_latency_milliseconds" >> "$TEMP_FILE"

kdc_success=0
if timeout 2 bash -c "</dev/tcp/$KDC_HOST/88" >/dev/null 2>&1; then
    kdc_success=1
fi
printf 'miniidm_kdc_port_up %s\n' "$kdc_success" >> "$TEMP_FILE"
printf 'miniidm_collection_timestamp_seconds %s\n' "$(date +%s)" >> "$TEMP_FILE"

chmod 0644 "$TEMP_FILE"
mv "$TEMP_FILE" "$METRICS_FILE"

print_ok "Metricas escritas en $METRICS_FILE"
