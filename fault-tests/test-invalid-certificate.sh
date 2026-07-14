#!/usr/bin/env bash

# reemplaza temporalmente un certificado de prueba; requiere --apply

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

case "$SERVICE_NAME" in
    apache2)
        TARGET_FILE="${TARGET_FILE:-/etc/apache2/miniidm/tls/web.fis.epn.ec.crt}"
        CONFIG_CHECK=(apache2ctl configtest)
        ;;
    haproxy)
        TARGET_FILE="${TARGET_FILE:-/etc/haproxy/miniidm/ldap.fis.epn.edu.ec.pem}"
        CONFIG_CHECK=(haproxy -c -f /etc/haproxy/haproxy.cfg)
        ;;
    *)
        print_error "Servicio no permitido: $SERVICE_NAME"
        exit 1
        ;;
esac

INVALID_FILE="${INVALID_FILE:-}"
RESULT_FILE="$PROJECT_DIR/results/faults/invalid-certificate.csv"
BACKUP_FILE=""
FILE_REPLACED=false

print_title "Prueba de certificado invalido"

require_command systemctl
require_command cp
require_command mktemp
require_command date

if [ "$SERVICE_NAME" = "apache2" ]; then
    require_command apache2ctl
else
    require_command haproxy
fi

if [ "$APPLY" = false ]; then
    print_info "Dry-run: no se reemplazara $TARGET_FILE"
    print_info "Para Apache, seleccione un certificado expirado de prueba con INVALID_FILE=/ruta/certificado-expirado.crt"
    print_info "Para HAProxy, INVALID_FILE debe ser un PEM de prueba completo con clave correspondiente"
    print_info "El modo --apply respalda, valida configuracion, reinicia y restaura el archivo mediante trap"
    exit 0
fi

require_root

if [ -z "$INVALID_FILE" ]; then
    print_error "Defina INVALID_FILE con un certificado o PEM de prueba invalido"
    exit 1
fi

check_file_exists "$TARGET_FILE"
check_file_exists "$INVALID_FILE"
"${CONFIG_CHECK[@]}"

restore_certificate() {
    if [ "$FILE_REPLACED" = true ]; then
        print_info "Restaurando certificado original en $TARGET_FILE"
        cp --preserve=mode,ownership "$BACKUP_FILE" "$TARGET_FILE" || print_error "No se pudo restaurar $TARGET_FILE"
        "${CONFIG_CHECK[@]}" && systemctl restart "$SERVICE_NAME" || print_error "No se pudo restaurar el servicio $SERVICE_NAME"
        FILE_REPLACED=false
    fi

    if [ -n "$BACKUP_FILE" ]; then
        rm -f "$BACKUP_FILE"
    fi
}

trap restore_certificate EXIT
initialize_csv "$RESULT_FILE" "timestamp,service,target_file,invalid_file,result"

BACKUP_FILE="$(mktemp "${TARGET_FILE}.miniidm-backup.XXXXXX")"
cp --preserve=mode,ownership "$TARGET_FILE" "$BACKUP_FILE"
FILE_REPLACED=true
cp --preserve=mode,ownership "$INVALID_FILE" "$TARGET_FILE"

if "${CONFIG_CHECK[@]}"; then
    systemctl restart "$SERVICE_NAME"
    result="invalid_certificate_loaded"
else
    result="configuration_rejected"
fi

append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$SERVICE_NAME" "$TARGET_FILE" "$INVALID_FILE" "$result"
print_info "Resultado temporal: $result; el trap restaurara el certificado original"
