#!/usr/bin/env bash

# mide la conmutación por error de LDAP al detener slapd en idm1; requiere --apply

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
LDAP1_URI="${LDAP1_URI:-ldaps://ldap1.fis.epn.ec:636}"
LDAP_BASE_DN="${LDAP_BASE_DN:-dc=fis,dc=epn,dc=ec}"
LDAP_FILTER="${LDAP_FILTER:-(uid=jperez)}"
CA_CERT="${CA_CERT:-$PROJECT_DIR/pki/certs/ca-root.crt}"
FAILOVER_TIMEOUT_SECONDS="${FAILOVER_TIMEOUT_SECONDS:-25}"
RESULT_FILE="$PROJECT_DIR/results/faults/ldap-failover.csv"
SLAPD_STOPPED=false

print_title "Prueba de conmutación por error de LDAP"

require_command hostname
require_command systemctl
require_command ldapsearch
require_command timeout
require_command date
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

ldap_check() {
    local uri="$1"
    local timeout_seconds="${2:-3}"

    run_with_timeout "$timeout_seconds" ldapsearch -x -LLL -H "$uri" -o "TLS_CACERT=$CA_CERT" -b "$LDAP_BASE_DN" "$LDAP_FILTER" uid >/dev/null 2>&1
}

if ! systemctl is-active --quiet slapd || ! systemctl is-active --quiet haproxy; then
    print_error "slapd y haproxy deben estar activos antes de la prueba"
    exit 1
fi

if [ "$APPLY" = false ]; then
    print_info "Simulación: se detendría slapd, se consultaría $LDAP_URI y se validaría la restauración directa a ldap1"
    print_info "No se puede confirmar de forma segura el servidor de HAProxy sin instrumentación adicional"
    exit 0
fi

require_root

restore_slapd() {
    if [ "$SLAPD_STOPPED" = true ]; then
        print_info "Restaurando slapd"
        if systemctl start slapd; then
            SLAPD_STOPPED=false
            return 0
        fi
        print_error "No se pudo restaurar slapd; la restauración manual se realiza con: sudo systemctl start slapd"
        return 1
    fi
}

trap restore_slapd EXIT
initialize_csv "$RESULT_FILE" "timestamp,first_success_after_stop_ms,restore_ms,ldap_direct_after,result"

print_info "Deteniendo slapd; la restauracion esta protegida por trap"
systemctl stop slapd
SLAPD_STOPPED=true
if systemctl is-active --quiet slapd; then
    print_error "slapd sigue activo despues de systemctl stop"
    exit 1
fi

start_ms="$(monotonic_milliseconds)"
deadline_ms="$((start_ms + FAILOVER_TIMEOUT_SECONDS * 1000))"
result="failover_timeout"
first_success_after_stop_ms="$((FAILOVER_TIMEOUT_SECONDS * 1000))"

while [ "$(monotonic_milliseconds)" -lt "$deadline_ms" ]; do
    remaining_ms="$((deadline_ms - $(monotonic_milliseconds)))"
    remaining_seconds="$(( (remaining_ms + 999) / 1000 ))"
    if ldap_check "$LDAP_URI" "$remaining_seconds"; then
        first_success_after_stop_ms="$(( $(monotonic_milliseconds) - start_ms ))"
        result="ok"
        break
    fi
    sleep 0.1
done

restore_start_ms="$(monotonic_milliseconds)"
if restore_slapd && systemctl is-active --quiet slapd; then
    restore_ms="$(( $(monotonic_milliseconds) - restore_start_ms ))"
else
    restore_ms="$(( $(monotonic_milliseconds) - restore_start_ms ))"
    append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$first_success_after_stop_ms" "$restore_ms" "0" "restore_failed"
    exit 1
fi

if tcp_check "ldap1.fis.epn.ec" 636 5 && ldap_check "$LDAP1_URI"; then
    ldap_direct_after=1
else
    ldap_direct_after=0
fi

if [ "$result" != "ok" ]; then
    result="failover_timeout"
elif [ "$ldap_direct_after" -ne 1 ]; then
    result="direct_ldap_restore_failed"
fi

append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$first_success_after_stop_ms" "$restore_ms" "$ldap_direct_after" "$result"
if [ "$result" != "ok" ]; then
    print_error "La prueba LDAP termino con $result"
    exit 1
fi

print_ok "Primera respuesta LDAP exitosa despues de detener ldap1: $first_success_after_stop_ms ms; restauracion en $restore_ms ms"
