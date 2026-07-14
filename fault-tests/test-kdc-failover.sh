#!/usr/bin/env bash

# mide failover KDC con accion manual o SSH explicita; requiere --apply

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/scripts/common-experiments.sh"

APPLY=false
MODE=""
SSH_TARGET=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --apply)
            APPLY=true
            ;;
        --manual)
            MODE="manual"
            ;;
        --ssh-primary)
            MODE="ssh"
            SSH_TARGET="${2:-}"
            if [ -z "$SSH_TARGET" ]; then
                print_error "--ssh-primary requiere USUARIO@idm1"
                exit 1
            fi
            shift
            ;;
        *)
            print_error "Uso: $0 [--apply] (--manual | --ssh-primary USUARIO@idm1)"
            exit 1
            ;;
    esac
    shift
done

USER_NAME="${KRB_USER:-jperez}"
REALM="FIS.EPN.EC"
KINIT_TIMEOUT_SECONDS="${KINIT_TIMEOUT_SECONDS:-30}"
RESULT_FILE="$PROJECT_DIR/results/faults/kdc-failover.csv"
PRIMARY_STOPPED_BY_SCRIPT=false

print_title "Prueba de failover KDC"

require_command kdestroy
require_command kinit
require_command klist
require_command date
require_command timeout
require_positive_integer "KINIT_TIMEOUT_SECONDS" "$KINIT_TIMEOUT_SECONDS"

if [ -z "$MODE" ]; then
    print_error "Seleccione --manual o --ssh-primary USUARIO@idm1"
    exit 1
fi

if [ "$APPLY" = false ]; then
    print_info "Dry-run: se obtendria una linea base con kinit para $USER_NAME@$REALM"
    if [ "$MODE" = "manual" ]; then
        print_info "Despues se solicitara detener krb5-kdc manualmente en idm1 y confirmar"
    else
        print_info "Se usaria SSH BatchMode hacia $SSH_TARGET; no se asumiran credenciales SSH"
    fi
    exit 0
fi

if [ "$MODE" = "ssh" ]; then
    require_command ssh
fi

restore_primary_kdc() {
    if [ "$PRIMARY_STOPPED_BY_SCRIPT" = true ]; then
        print_info "Restaurando krb5-kdc en idm1 mediante SSH"
        ssh -o BatchMode=yes "$SSH_TARGET" "sudo -n systemctl start krb5-kdc" || print_error "No se pudo restaurar krb5-kdc automaticamente"
        PRIMARY_STOPPED_BY_SCRIPT=false
    fi
}

trap restore_primary_kdc EXIT
initialize_csv "$RESULT_FILE" "timestamp,mode,principal,baseline_ms,failover_ms,result"

kdestroy || true
baseline_start_ms="$(monotonic_milliseconds)"
run_with_timeout "$KINIT_TIMEOUT_SECONDS" kinit "$USER_NAME@$REALM"
baseline_ms="$(( $(monotonic_milliseconds) - baseline_start_ms ))"
klist -s
print_info "Autenticacion normal completada en $baseline_ms ms"

if [ "$MODE" = "manual" ]; then
    print_info "Detenga ahora krb5-kdc en idm1 desde otra sesion y confirme cuando este caido"
    read -r -p "Escriba CONTINUAR para medir el failover: " confirmation
    if [ "$confirmation" != "CONTINUAR" ]; then
        print_error "Prueba cancelada; no se modifico el KDC primario"
        exit 1
    fi
else
    print_info "Deteniendo krb5-kdc en idm1 mediante SSH configurado explicitamente"
    ssh -o BatchMode=yes "$SSH_TARGET" "sudo -n systemctl stop krb5-kdc"
    PRIMARY_STOPPED_BY_SCRIPT=true
fi

kdestroy || true
failover_start_ms="$(monotonic_milliseconds)"
if run_with_timeout "$KINIT_TIMEOUT_SECONDS" kinit "$USER_NAME@$REALM"; then
    failover_ms="$(( $(monotonic_milliseconds) - failover_start_ms ))"
    result="ok"
else
    failover_ms="$(( $(monotonic_milliseconds) - failover_start_ms ))"
    result="failed"
fi

append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$MODE" "$USER_NAME@$REALM" "$baseline_ms" "$failover_ms" "$result"
if [ "$result" != "ok" ]; then
    print_error "kinit no pudo autenticar durante el failover"
    exit 1
fi

print_ok "Failover KDC en $failover_ms ms"
