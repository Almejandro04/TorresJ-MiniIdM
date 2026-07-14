#!/usr/bin/env bash

# mata el PID principal de un servicio permitido; requiere --apply

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/scripts/common-experiments.sh"

SERVICE_NAME="${1:-}"
APPLY=false
if [ "${2:-}" = "--apply" ]; then
    APPLY=true
fi

if [ -z "$SERVICE_NAME" ] || [ "$#" -gt 2 ]; then
    print_error "Uso: $0 {slapd|apache2|haproxy|krb5-kdc} [--apply]"
    exit 1
fi

case "$SERVICE_NAME" in
    slapd|apache2|haproxy|krb5-kdc) ;;
    *)
        print_error "Servicio no permitido: $SERVICE_NAME"
        exit 1
        ;;
esac

RECOVERY_TIMEOUT_SECONDS="${RECOVERY_TIMEOUT_SECONDS:-30}"
RESULT_FILE="$PROJECT_DIR/results/faults/service-kill.csv"
SERVICE_KILLED=false

print_title "Prueba de recuperacion tras kill -9"

require_command systemctl
require_command kill
require_command date
require_positive_integer "RECOVERY_TIMEOUT_SECONDS" "$RECOVERY_TIMEOUT_SECONDS"

if [ "$RECOVERY_TIMEOUT_SECONDS" -gt 60 ]; then
    print_error "RECOVERY_TIMEOUT_SECONDS no puede superar 60"
    exit 1
fi

if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    print_error "El servicio no esta activo: $SERVICE_NAME"
    exit 1
fi

MAIN_PID="$(systemctl show --property MainPID --value "$SERVICE_NAME")"
if [ "$MAIN_PID" -le 0 ]; then
    print_error "No se obtuvo un PID principal valido para $SERVICE_NAME"
    exit 1
fi

if [ "$APPLY" = false ]; then
    print_info "Dry-run: se ejecutaria kill -9 sobre PID $MAIN_PID de $SERVICE_NAME"
    print_info "Systemd se esperaria durante un maximo de $RECOVERY_TIMEOUT_SECONDS s"
    exit 0
fi

require_root

restore_service() {
    if [ "$SERVICE_KILLED" = true ] && ! systemctl is-active --quiet "$SERVICE_NAME"; then
        print_info "Intentando restaurar $SERVICE_NAME"
        systemctl start "$SERVICE_NAME" || print_error "No se pudo iniciar $SERVICE_NAME automaticamente"
    fi
}

trap restore_service EXIT
initialize_csv "$RESULT_FILE" "timestamp,service,recovery_ms,result"

start_ms="$(monotonic_milliseconds)"
kill -9 "$MAIN_PID"
SERVICE_KILLED=true
deadline_ms="$((start_ms + RECOVERY_TIMEOUT_SECONDS * 1000))"
result="timeout"
recovery_ms="$((RECOVERY_TIMEOUT_SECONDS * 1000))"

while [ "$(monotonic_milliseconds)" -lt "$deadline_ms" ]; do
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        recovery_ms="$(( $(monotonic_milliseconds) - start_ms ))"
        result="ok"
        break
    fi
    sleep 0.1
done

append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$SERVICE_NAME" "$recovery_ms" "$result"
if [ "$result" != "ok" ]; then
    print_error "$SERVICE_NAME no se recupero antes del timeout"
    exit 1
fi

print_ok "$SERVICE_NAME recuperado en $recovery_ms ms"
