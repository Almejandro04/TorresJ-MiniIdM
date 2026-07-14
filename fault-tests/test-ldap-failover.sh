#!/usr/bin/env bash

# mide failover LDAP al detener slapd en idm1; requiere --apply

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/scripts/common-experiments.sh"

APPLY=false
if [ "${1:-}" = "--apply" ]; then
    APPLY=true
    shift
fi

if [ "$#" -ne 0 ]; then
    print_error "Uso: $0 [--apply]"
    exit 1
fi

LDAP_URI="${LDAP_URI:-ldaps://ldap.fis.epn.edu.ec:1636}"
LDAP_BASE_DN="${LDAP_BASE_DN:-dc=fis,dc=epn,dc=ec}"
CA_CERT="${CA_CERT:-$PROJECT_DIR/pki/certs/ca-root.crt}"
FAILOVER_TIMEOUT_SECONDS="${FAILOVER_TIMEOUT_SECONDS:-25}"
RESULT_FILE="$PROJECT_DIR/results/faults/ldap-failover.csv"
SLAPD_STOPPED=false

print_title "Prueba de failover LDAP"

require_command hostname
require_command systemctl
require_command ldapsearch
require_command timeout
require_command date
require_command awk
require_positive_integer "FAILOVER_TIMEOUT_SECONDS" "$FAILOVER_TIMEOUT_SECONDS"
check_file_exists "$CA_CERT"

if [ "$FAILOVER_TIMEOUT_SECONDS" -gt 25 ]; then
    print_error "FAILOVER_TIMEOUT_SECONDS no puede superar 25 para restaurar slapd antes de 30 s"
    exit 1
fi

if [ "$(hostname -s)" != "idm1" ]; then
    print_error "Esta prueba debe ejecutarse en idm1"
    exit 1
fi

if ! systemctl is-active --quiet slapd || ! systemctl is-active --quiet haproxy; then
    print_error "slapd y haproxy deben estar activos antes de la prueba"
    exit 1
fi

if [ "$APPLY" = false ]; then
    print_info "Dry-run: validado estado inicial de slapd y haproxy"
    print_info "Se detendria slapd, se consultaria $LDAP_URI y se restauraria en menos de $FAILOVER_TIMEOUT_SECONDS s"
    exit 0
fi

require_root

restore_slapd() {
    if [ "$SLAPD_STOPPED" = true ]; then
        print_info "Restaurando slapd"
        if systemctl start slapd; then
            SLAPD_STOPPED=false
        else
            print_error "No se pudo restaurar slapd automaticamente"
        fi
    fi
}

trap restore_slapd EXIT
initialize_csv "$RESULT_FILE" "timestamp,failover_ms,result"

print_info "Deteniendo slapd; la restauracion esta protegida por trap"
systemctl stop slapd
SLAPD_STOPPED=true
start_ms="$(monotonic_milliseconds)"
deadline_ms="$((start_ms + FAILOVER_TIMEOUT_SECONDS * 1000))"
result="timeout"
failover_ms="$((FAILOVER_TIMEOUT_SECONDS * 1000))"

while [ "$(monotonic_milliseconds)" -lt "$deadline_ms" ]; do
    remaining_ms="$((deadline_ms - $(monotonic_milliseconds)))"
    remaining_seconds="$(awk -v milliseconds="$remaining_ms" 'BEGIN { printf "%.3f", milliseconds / 1000 }')"
    if run_with_timeout "$remaining_seconds" ldapsearch -x -LLL -H "$LDAP_URI" -o "TLS_CACERT=$CA_CERT" -b "$LDAP_BASE_DN" "(uid=jperez)" uid >/dev/null 2>&1; then
        failover_ms="$(( $(monotonic_milliseconds) - start_ms ))"
        result="ok"
        break
    fi
    sleep 0.1
done

restore_slapd
if ! systemctl is-active --quiet slapd; then
    print_error "slapd no se recupero despues de la prueba"
    exit 1
fi

append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$failover_ms" "$result"
if [ "$result" != "ok" ]; then
    print_error "HAProxy no respondio antes del timeout"
    exit 1
fi

print_ok "Failover LDAP en $failover_ms ms"
