#!/usr/bin/env bash

# mata un MainPID permitido y mide una recuperacion funcional; requiere --apply

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
FUNCTIONAL_TIMEOUT_SECONDS="${FUNCTIONAL_TIMEOUT_SECONDS:-5}"
SLAPD_HOST="${SLAPD_HOST:-127.0.0.1}"
SLAPD_PORT="${SLAPD_PORT:-389}"
APACHE_HOST="${APACHE_HOST:-127.0.0.1}"
APACHE_PORT="${APACHE_PORT:-443}"
HAPROXY_HOST="${HAPROXY_HOST:-127.0.0.1}"
HAPROXY_PORT="${HAPROXY_PORT:-1636}"
HAPROXY_LDAP_URI="${HAPROXY_LDAP_URI:-ldaps://ldap.fis.epn.edu.ec:1636}"
HAPROXY_LDAP_BASE_DN="${HAPROXY_LDAP_BASE_DN:-dc=fis,dc=epn,dc=ec}"
HAPROXY_CA_CERT="${HAPROXY_CA_CERT:-$PROJECT_DIR/pki/certs/ca-root.crt}"
KDC_HOST="${KDC_HOST:-127.0.0.1}"
KDC_PORT="${KDC_PORT:-88}"
RESULT_FILE="$PROJECT_DIR/results/faults/service-kill.csv"
SERVICE_KILLED=false

print_title "Prueba de recuperacion tras kill -9"

require_command systemctl
require_command kill
require_command date
require_positive_integer "RECOVERY_TIMEOUT_SECONDS" "$RECOVERY_TIMEOUT_SECONDS"
require_positive_integer "FUNCTIONAL_TIMEOUT_SECONDS" "$FUNCTIONAL_TIMEOUT_SECONDS"

if [ "$RECOVERY_TIMEOUT_SECONDS" -gt 60 ]; then
    print_error "RECOVERY_TIMEOUT_SECONDS no puede superar 60"
    exit 1
fi

if ! systemctl is-active --quiet "$SERVICE_NAME"; then
    print_error "El servicio no esta activo: $SERVICE_NAME"
    exit 1
fi

OLD_MAIN_PID="$(systemctl show --property MainPID --value "$SERVICE_NAME")"
RESTART_POLICY="$(systemctl show --property Restart --value "$SERVICE_NAME")"
if [ "$OLD_MAIN_PID" -le 0 ]; then
    print_error "No se obtuvo un PID principal valido para $SERVICE_NAME"
    exit 1
fi

if [ "$APPLY" = false ]; then
    print_info "Simulación: se ejecutaría kill -9 sobre el PID $OLD_MAIN_PID de $SERVICE_NAME"
    print_info "Restart=$RESTART_POLICY; se exigiria un MainPID nuevo y una comprobacion funcional"
    exit 0
fi

require_root

restore_service() {
    if [ "$SERVICE_KILLED" = true ] && ! systemctl is-active --quiet "$SERVICE_NAME"; then
        print_info "Intentando restaurar $SERVICE_NAME"
        systemctl start "$SERVICE_NAME" || print_error "No se pudo iniciar $SERVICE_NAME automaticamente"
    fi
}

wait_for_transition() {
    local deadline_ms current_pid service_state
    deadline_ms="$(( $(monotonic_milliseconds) + FUNCTIONAL_TIMEOUT_SECONDS * 1000 ))"

    while [ "$(monotonic_milliseconds)" -lt "$deadline_ms" ]; do
        current_pid="$(systemctl show --property MainPID --value "$SERVICE_NAME")"
        service_state="$(systemctl is-active "$SERVICE_NAME" 2>/dev/null || true)"
        if ! kill -0 "$OLD_MAIN_PID" 2>/dev/null || [ "$current_pid" != "$OLD_MAIN_PID" ]; then
            return 0
        fi
        case "$service_state" in
            inactive|failed|activating|deactivating) return 0 ;;
        esac
        sleep 0.1
    done

    print_error "Systemd no mostro transicion despues de matar el PID $OLD_MAIN_PID"
    return 1
}

functional_check() {
    case "$SERVICE_NAME" in
        slapd)
            tcp_check "$SLAPD_HOST" "$SLAPD_PORT" "$FUNCTIONAL_TIMEOUT_SECONDS"
            ;;
        apache2)
            tcp_check "$APACHE_HOST" "$APACHE_PORT" "$FUNCTIONAL_TIMEOUT_SECONDS"
            ;;
        haproxy)
            if command -v ldapsearch >/dev/null 2>&1 && [ -f "$HAPROXY_CA_CERT" ]; then
                run_with_timeout "$FUNCTIONAL_TIMEOUT_SECONDS" ldapsearch -x -LLL -H "$HAPROXY_LDAP_URI" -o "TLS_CACERT=$HAPROXY_CA_CERT" -b "$HAPROXY_LDAP_BASE_DN" "(uid=jperez)" uid >/dev/null 2>&1
            else
                tcp_check "$HAPROXY_HOST" "$HAPROXY_PORT" "$FUNCTIONAL_TIMEOUT_SECONDS"
            fi
            ;;
        krb5-kdc)
            tcp_check "$KDC_HOST" "$KDC_PORT" "$FUNCTIONAL_TIMEOUT_SECONDS"
            ;;
    esac
}

trap restore_service EXIT
initialize_csv "$RESULT_FILE" "timestamp,service,old_pid,new_pid,recovery_ms,result"

start_ms="$(monotonic_milliseconds)"
kill -9 "$OLD_MAIN_PID"
SERVICE_KILLED=true

if ! wait_for_transition; then
    NEW_MAIN_PID="$(systemctl show --property MainPID --value "$SERVICE_NAME")"
    recovery_ms="$(( $(monotonic_milliseconds) - start_ms ))"
    append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$SERVICE_NAME" "$OLD_MAIN_PID" "$NEW_MAIN_PID" "$recovery_ms" "transition_timeout"
    exit 1
fi

if [ "$RESTART_POLICY" = "no" ]; then
    NEW_MAIN_PID="$(systemctl show --property MainPID --value "$SERVICE_NAME")"
    recovery_ms="$(( $(monotonic_milliseconds) - start_ms ))"
    print_error "$SERVICE_NAME tiene Restart=no; systemd no tiene recuperacion automatica configurada"
    append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$SERVICE_NAME" "$OLD_MAIN_PID" "$NEW_MAIN_PID" "$recovery_ms" "no_auto_restart"
    exit 0
fi

if NEW_MAIN_PID="$(wait_for_new_main_pid "$SERVICE_NAME" "$OLD_MAIN_PID" "$RECOVERY_TIMEOUT_SECONDS")"; then
    recovery_ms="$(( $(monotonic_milliseconds) - start_ms ))"
    if functional_check; then
        result="ok"
    else
        result="functional_check_failed"
    fi
else
    NEW_MAIN_PID="$(systemctl show --property MainPID --value "$SERVICE_NAME")"
    recovery_ms="$(( $(monotonic_milliseconds) - start_ms ))"
    result="recovery_timeout"
fi

append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$SERVICE_NAME" "$OLD_MAIN_PID" "$NEW_MAIN_PID" "$recovery_ms" "$result"
if [ "$result" != "ok" ]; then
    print_error "$SERVICE_NAME no supero la recuperacion funcional: $result"
    exit 1
fi

print_ok "$SERVICE_NAME recuperado funcionalmente en $recovery_ms ms con PID $NEW_MAIN_PID"
