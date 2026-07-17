#!/usr/bin/env bash

# configuracion consumidor ldap2

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

CONSUMER_LDIF="$PROJECT_DIR/ldap/config/ldap2/replication-consumer.ldif"
DRY_RUN=false
TEMP_LDIF=""

case "${1:-}" in
    "")
        ;;
    --dry-run)
        DRY_RUN=true
        ;;
    *)
        print_error "Uso: $0 [--dry-run]"
        exit 1
        ;;
esac

cleanup() {
    if [ -n "$TEMP_LDIF" ] && [ -f "$TEMP_LDIF" ]; then
        rm -f -- "$TEMP_LDIF"
    fi
    unset REPLICATION_PASSWORD escaped_password
}

trap cleanup EXIT

print_title "Configuracion consumidor ldap2"

require_root
require_command ldapsearch
require_command ldapmodify
require_command cp
require_command mktemp
require_command rm
require_command sed
check_file_exists "$CONSUMER_LDIF"

if ! grep -Fq 'credentials=REPLACE_WITH_PASSWORD' "$CONSUMER_LDIF"; then
    print_error "La plantilla debe conservar credentials=REPLACE_WITH_PASSWORD"
    print_error "No guardar la contrasena real en Git"
    exit 1
fi

if [ "$DRY_RUN" = true ]; then
    print_info "Simulación: la plantilla fue validada; cn=config no fue consultado ni modificado"
    exit 0
fi

if ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config '(olcDatabase=mdb)' olcSyncrepl | grep -F 'rid=002' >/dev/null; then
    print_info "Consumidor rid=002 ya configurado"
else
    ldapsearch_status="${PIPESTATUS[0]}"
    if [ "$ldapsearch_status" -ne 0 ]; then
        print_error "No se pudo consultar la configuracion actual de syncrepl"
        exit 1
    fi

    if ! read -r -s -p "Contrasena de svc-replica: " REPLICATION_PASSWORD; then
        printf '\n'
        print_error "No se pudo leer la contrasena de replicacion"
        exit 1
    fi
    printf '\n'

    if [ -z "$REPLICATION_PASSWORD" ]; then
        print_error "La contrasena de replicacion no puede estar vacia"
        exit 1
    fi

    umask 077
    TEMP_LDIF="$(mktemp "${TMPDIR:-/tmp}/miniidm-replication-consumer.XXXXXX")"
    cp -- "$CONSUMER_LDIF" "$TEMP_LDIF"
    escaped_password="$(printf '%s' "$REPLICATION_PASSWORD" | sed -e 's/[\\&|]/\\&/g')"
    sed -i "s|REPLACE_WITH_PASSWORD|$escaped_password|g" "$TEMP_LDIF"

    print_info "Aplicando la configuración del consumidor"
    ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f "$TEMP_LDIF"
fi

print_ok "ldap2 configurado como consumidor de replicacion"
