#!/usr/bin/env bash

# prueba temporalmente un certificado invalido; requiere --apply

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/scripts/common-experiments.sh"

SERVICE_NAME="${1:-apache2}"
APPLY=false
if [ "${2:-}" = "--apply" ]; then
    APPLY=true
fi

if [ "$#" -gt 2 ]; then
    print_error "Uso: $0 [apache2|haproxy] [--apply]"
    exit 1
fi

TLS_CA_CERT="${TLS_CA_CERT:-$PROJECT_DIR/pki/certs/ca-root.crt}"
INVALID_FILE="${INVALID_FILE:-}"
RESULT_FILE="$PROJECT_DIR/results/faults/invalid-certificate.csv"
BACKUP_FILE=""
FILE_REPLACED=false
RESTORE_CONFIRMED=false

case "$SERVICE_NAME" in
    apache2)
        TARGET_FILE="${TARGET_FILE:-/etc/apache2/miniidm/tls/web.fis.epn.ec.crt}"
        INSTALLED_KEY="${INSTALLED_KEY:-/etc/apache2/miniidm/tls/web.fis.epn.ec.key}"
        APACHE_URL="${APACHE_URL:-https://web.fis.epn.ec/}"
        CONFIG_CHECK=(apache2ctl configtest)
        ;;
    haproxy)
        TARGET_FILE="${TARGET_FILE:-/etc/haproxy/miniidm/ldap.fis.epn.edu.ec.pem}"
        HAPROXY_TLS_HOST="${HAPROXY_TLS_HOST:-ldap.fis.epn.edu.ec}"
        HAPROXY_TLS_PORT="${HAPROXY_TLS_PORT:-1636}"
        CONFIG_CHECK=(haproxy -c -f /etc/haproxy/haproxy.cfg)
        ;;
    *)
        print_error "Servicio no permitido: $SERVICE_NAME"
        exit 1
        ;;
esac

print_title "Prueba de certificado invalido"

require_command systemctl
require_command cp
require_command stat
require_command openssl
require_command date
require_command timeout
require_command sha256sum
require_command awk
require_nonempty "INVALID_FILE" "$INVALID_FILE"
check_file_exists "$INVALID_FILE"
check_file_exists "$TLS_CA_CERT"

if [ "$SERVICE_NAME" = "apache2" ]; then
    require_command apache2ctl
    require_command curl
    check_file_exists "$INSTALLED_KEY"
else
    require_command haproxy
fi

if ! openssl x509 -in "$INVALID_FILE" -noout >/dev/null 2>&1; then
    print_error "INVALID_FILE debe contener un certificado PEM valido"
    exit 1
fi

public_key_fingerprint() {
    local certificate_file="$1"
    local key_file="$2"
    local certificate_hash key_hash

    certificate_hash="$(openssl x509 -in "$certificate_file" -pubkey -noout | openssl pkey -pubin -pubout | sha256sum | awk '{ print $1 }')"
    key_hash="$(openssl pkey -in "$key_file" -pubout | sha256sum | awk '{ print $1 }')"
    [ "$certificate_hash" = "$key_hash" ]
}

if [ "$SERVICE_NAME" = "apache2" ]; then
    if public_key_fingerprint "$INVALID_FILE" "$INSTALLED_KEY"; then
        print_info "El certificado de prueba corresponde a la clave instalada de Apache"
    else
        print_error "El certificado de prueba no corresponde a la clave Apache; es probable que configtest lo rechace"
    fi
else
    if ! openssl pkey -in "$INVALID_FILE" -noout >/dev/null 2>&1; then
        print_error "Para HAProxy, INVALID_FILE debe ser un PEM completo con clave privada"
        exit 1
    fi
    if ! public_key_fingerprint "$INVALID_FILE" "$INVALID_FILE"; then
        print_error "El certificado y la clave de INVALID_FILE no corresponden"
        exit 1
    fi
fi

tls_client_check() {
    if [ "$SERVICE_NAME" = "apache2" ]; then
        run_with_timeout 5 curl --silent --show-error --output /dev/null --cacert "$TLS_CA_CERT" "$APACHE_URL"
    else
        run_with_timeout 5 openssl s_client -connect "$HAPROXY_TLS_HOST:$HAPROXY_TLS_PORT" -servername "$HAPROXY_TLS_HOST" -verify_hostname "$HAPROXY_TLS_HOST" -CAfile "$TLS_CA_CERT" -verify_return_error </dev/null >/dev/null
    fi
}

if [ "$APPLY" = false ]; then
    print_info "Simulación: se validaron el formato y la compatibilidad de INVALID_FILE sin modificar $TARGET_FILE"
    print_info "Con --apply se respaldara el archivo, se esperara rechazo TLS del cliente y se restaurara mediante trap"
    exit 0
fi

require_root
check_file_exists "$TARGET_FILE"
"${CONFIG_CHECK[@]}"
if ! systemctl is-active --quiet "$SERVICE_NAME" || ! tls_client_check; then
    print_error "El servicio actual debe estar activo y pasar la verificacion TLS antes de la prueba"
    exit 1
fi

restore_original() {
    local config_ok=false tls_ok=false

    if [ "$FILE_REPLACED" = true ]; then
        print_info "Restaurando archivo original en $TARGET_FILE"
        if cp --preserve=mode,ownership "$BACKUP_FILE" "$TARGET_FILE"; then
            if "${CONFIG_CHECK[@]}" && systemctl restart "$SERVICE_NAME"; then
                config_ok=true
                if tls_client_check; then
                    tls_ok=true
                fi
            fi
        fi

        if [ "$config_ok" = true ] && [ "$tls_ok" = true ]; then
            RESTORE_CONFIRMED=true
            FILE_REPLACED=false
            safe_remove_temp_file "$BACKUP_FILE"
            BACKUP_FILE=""
        else
            print_error "La restauracion no se confirmo; conserve $BACKUP_FILE y ejecute validacion/reinicio manual"
        fi
    fi
}

trap restore_original EXIT
initialize_csv "$RESULT_FILE" "timestamp,service,target_file,invalid_file,config_result,tls_invalid_result,restore_result,result"

BACKUP_MODE="$(stat -c '%a' "$TARGET_FILE")"
BACKUP_OWNER="$(stat -c '%U' "$TARGET_FILE")"
BACKUP_GROUP="$(stat -c '%G' "$TARGET_FILE")"
BACKUP_FILE="$(safe_temp_file "${TARGET_FILE}.miniidm-backup.XXXXXX")"
cp --preserve=mode,ownership "$TARGET_FILE" "$BACKUP_FILE"

FILE_REPLACED=true
cp --preserve=mode,ownership "$INVALID_FILE" "$TARGET_FILE"

if "${CONFIG_CHECK[@]}"; then
    config_result="config_passed"
    if systemctl restart "$SERVICE_NAME"; then
        if tls_client_check; then
            tls_invalid_result="unexpected_tls_success"
            result="unexpected_tls_success"
        else
            tls_invalid_result="expected_tls_failure"
            result="expected_tls_failure"
        fi
    else
        tls_invalid_result="not_run"
        result="service_restart_failed"
    fi
else
    config_result="configuration_rejected"
    tls_invalid_result="not_run"
    result="configuration_rejected"
fi

restore_original
if [ "$RESTORE_CONFIRMED" = true ]; then
    restore_result="restored"
else
    restore_result="restore_failed"
fi

append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$SERVICE_NAME" "$TARGET_FILE" "$INVALID_FILE" "$config_result" "$tls_invalid_result" "$restore_result" "$result"
if [ "$RESTORE_CONFIRMED" != true ]; then
    print_error "Restauracion incompleta. Respaldo: $BACKUP_FILE (modo $BACKUP_MODE, $BACKUP_OWNER:$BACKUP_GROUP)"
    exit 1
fi

print_ok "Prueba de certificado registrada como $result y restaurada correctamente"
