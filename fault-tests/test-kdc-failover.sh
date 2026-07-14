#!/usr/bin/env bash

# mide failover KDC con keytab de prueba; requiere --apply

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/scripts/common-experiments.sh"

APPLY=false
MODE=""
SSH_TARGET=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --apply) APPLY=true ;;
        --manual) MODE="manual" ;;
        --ssh-primary)
            MODE="ssh"
            SSH_TARGET="${2:-}"
            require_nonempty "USUARIO@idm1 para --ssh-primary" "$SSH_TARGET"
            shift
            ;;
        *)
            print_error "Uso: $0 [--apply] (--manual | --ssh-primary USUARIO@idm1)"
            exit 1
            ;;
    esac
    shift
done

KRB_TEST_KEYTAB="${KRB_TEST_KEYTAB:-}"
KRB_TEST_PRINCIPAL="${KRB_TEST_PRINCIPAL:-}"
KINIT_TIMEOUT_SECONDS="${KINIT_TIMEOUT_SECONDS:-30}"
PRIMARY_KDC_HOST="${PRIMARY_KDC_HOST:-kdc1.fis.epn.ec}"
PRIMARY_KDC_PORT="${PRIMARY_KDC_PORT:-88}"
RESULT_FILE="$PROJECT_DIR/results/faults/kdc-failover.csv"
PRIMARY_STOPPED_BY_SCRIPT=false
TRACE_FILE=""

print_title "Prueba de failover KDC"

require_command kdestroy
require_command kinit
require_command klist
require_command timeout
require_command grep
require_command sed
require_command tail
require_command date
require_positive_integer "KINIT_TIMEOUT_SECONDS" "$KINIT_TIMEOUT_SECONDS"
require_nonempty "KRB_TEST_KEYTAB" "$KRB_TEST_KEYTAB"
require_nonempty "KRB_TEST_PRINCIPAL" "$KRB_TEST_PRINCIPAL"
check_file_exists "$KRB_TEST_KEYTAB"
require_file_not_world_readable "$KRB_TEST_KEYTAB"

if [ -z "$MODE" ]; then
    print_error "Seleccione --manual o --ssh-primary USUARIO@idm1"
    exit 1
fi

if [ "$APPLY" = false ]; then
    print_info "Dry-run: se usaria kinit -k con KRB_TEST_KEYTAB sin imprimir su contenido"
    print_info "Principal de prueba: $KRB_TEST_PRINCIPAL"
    print_info "El trace temporal identificaria el KDC usado y se eliminaria al finalizar"
    exit 0
fi

if [ "$MODE" = "ssh" ]; then
    require_command ssh
fi

restore_primary_kdc() {
    if [ "$PRIMARY_STOPPED_BY_SCRIPT" = true ]; then
        print_info "Restaurando krb5-kdc en idm1 mediante SSH"
        if ssh -o BatchMode=yes "$SSH_TARGET" "sudo -n systemctl start krb5-kdc"; then
            PRIMARY_STOPPED_BY_SCRIPT=false
        else
            print_error "No se pudo restaurar krb5-kdc automaticamente"
        fi
    fi
}

cleanup() {
    restore_primary_kdc
    if [ -n "$TRACE_FILE" ]; then
        safe_remove_temp_file "$TRACE_FILE" || true
    fi
}

extract_kdc_from_trace() {
    local trace_path="$1"

    grep -Eo '([[:alnum:].-]+):88' "$trace_path" 2>/dev/null | tail -n 1 | sed 's/:88$//' || true
}

measured_kinit() {
    local label="$1"
    local start_ms end_ms trace_kdc

    kdestroy || true
    TRACE_FILE="$(safe_temp_file "${TMPDIR:-/tmp}/miniidm-kdc-trace.XXXXXX")"
    start_ms="$(monotonic_milliseconds)"
    if KRB5_TRACE="$TRACE_FILE" run_with_timeout "$KINIT_TIMEOUT_SECONDS" kinit -k -t "$KRB_TEST_KEYTAB" "$KRB_TEST_PRINCIPAL"; then
        end_ms="$(monotonic_milliseconds)"
        MEASURED_MS="$((end_ms - start_ms))"
        if klist -s; then
            MEASURED_RESULT="ok"
        else
            MEASURED_RESULT="failed"
            print_error "kinit finalizo, pero klist -s no encontro credenciales validas"
        fi
    else
        end_ms="$(monotonic_milliseconds)"
        MEASURED_MS="$((end_ms - start_ms))"
        MEASURED_RESULT="failed"
    fi
    trace_kdc="$(extract_kdc_from_trace "$TRACE_FILE")"
    MEASURED_KDC="${trace_kdc:-unknown}"
    safe_remove_temp_file "$TRACE_FILE"
    TRACE_FILE=""
    print_info "$label: $MEASURED_RESULT en $MEASURED_MS ms; KDC=$MEASURED_KDC"
    [ "$MEASURED_RESULT" = "ok" ]
}

trap cleanup EXIT
initialize_csv "$RESULT_FILE" "timestamp,mode,principal,baseline_ms,failover_ms,kdc_used,result"

if ! measured_kinit "Linea base"; then
    print_error "La autenticacion inicial con el keytab de prueba fallo"
    exit 1
fi
baseline_ms="$MEASURED_MS"

if [ "$MODE" = "manual" ]; then
    print_info "Detenga krb5-kdc en idm1 desde otra sesion y escriba DETENIDO"
    read -r -p "Confirmacion: " confirmation
    if [ "$confirmation" != "DETENIDO" ]; then
        print_error "Prueba cancelada; el script no detuvo el KDC primario"
        exit 1
    fi
else
    print_info "Verificando SSH BatchMode y sudo -n antes de detener el KDC"
    ssh -o BatchMode=yes "$SSH_TARGET" "sudo -n true && sudo -n systemctl is-active --quiet krb5-kdc"
    ssh -o BatchMode=yes "$SSH_TARGET" "sudo -n systemctl stop krb5-kdc"
    PRIMARY_STOPPED_BY_SCRIPT=true
fi

if measured_kinit "Failover"; then
    failover_ms="$MEASURED_MS"
    kdc_used="$MEASURED_KDC"
    result="ok"
else
    failover_ms="$MEASURED_MS"
    kdc_used="$MEASURED_KDC"
    result="failed"
fi

append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$MODE" "$KRB_TEST_PRINCIPAL" "$baseline_ms" "$failover_ms" "$kdc_used" "$result"

if [ "$MODE" = "manual" ]; then
    print_info "Restaure krb5-kdc en idm1 y escriba RESTAURADO"
    read -r -p "Confirmacion: " restored
    if [ "$restored" != "RESTAURADO" ]; then
        print_error "Debe restaurar manualmente: sudo systemctl start krb5-kdc"
        exit 1
    fi
else
    restore_primary_kdc
fi

if ! tcp_check "$PRIMARY_KDC_HOST" "$PRIMARY_KDC_PORT" 5; then
    print_error "El puerto 88 del KDC primario no responde; restaure con systemctl start krb5-kdc"
    exit 1
fi

if [ "$result" != "ok" ]; then
    print_error "El failover KDC no completo kinit con el keytab de prueba"
    exit 1
fi

print_ok "Failover KDC en $failover_ms ms; respondio $kdc_used"
