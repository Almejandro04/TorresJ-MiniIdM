#!/usr/bin/env bash

# bloquea temporalmente LDAP entre idm1 e idm2; requiere --apply

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

LOCAL_HOST="$(hostname -s)"
case "$LOCAL_HOST" in
    idm1) REMOTE_IP="${REMOTE_IP:-192.168.56.11}" ;;
    idm2) REMOTE_IP="${REMOTE_IP:-192.168.56.10}" ;;
    *)
        print_error "Esta prueba solo se permite en idm1 o idm2"
        exit 1
        ;;
esac

LDAP_PORT="${LDAP_PORT:-636}"
PARTITION_SECONDS="${PARTITION_SECONDS:-10}"
RULES_FILE="$PROJECT_DIR/results/faults/network-partition-rules.txt"
RULE_COMMENT="miniidm-ldap-partition-$$"
RULES_APPLIED=false

print_title "Prueba de particion de red LDAP"

require_command hostname
require_command iptables
require_command timeout
require_command date
require_positive_integer "PARTITION_SECONDS" "$PARTITION_SECONDS"

case "$LDAP_PORT" in
    389|636) ;;
    *)
        print_error "LDAP_PORT solo puede ser 389 o 636"
        exit 1
        ;;
esac

if [ "$PARTITION_SECONDS" -gt 20 ]; then
    print_error "PARTITION_SECONDS no puede superar 20 por seguridad"
    exit 1
fi

output_rule=(iptables -I OUTPUT -p tcp -d "$REMOTE_IP" --dport "$LDAP_PORT" -m comment --comment "$RULE_COMMENT" -j DROP)
input_rule=(iptables -I INPUT -p tcp -s "$REMOTE_IP" --sport "$LDAP_PORT" -m comment --comment "$RULE_COMMENT" -j DROP)

if [ "$APPLY" = false ]; then
    print_info "Dry-run: se verificaria conectividad TCP a $REMOTE_IP:$LDAP_PORT"
    print_info "Regla propuesta: ${output_rule[*]}"
    print_info "Regla propuesta: ${input_rule[*]}"
    print_info "Las reglas se eliminarian automaticamente tras $PARTITION_SECONDS s"
    exit 0
fi

require_root

cleanup_rules() {
    if [ "$RULES_APPLIED" = true ]; then
        print_info "Eliminando reglas de particion MiniIdM"
        iptables -D OUTPUT -p tcp -d "$REMOTE_IP" --dport "$LDAP_PORT" -m comment --comment "$RULE_COMMENT" -j DROP || true
        iptables -D INPUT -p tcp -s "$REMOTE_IP" --sport "$LDAP_PORT" -m comment --comment "$RULE_COMMENT" -j DROP || true
        RULES_APPLIED=false
    fi
}

trap cleanup_rules EXIT

if ! timeout 3 bash -c "</dev/tcp/$REMOTE_IP/$LDAP_PORT" >/dev/null 2>&1; then
    print_error "No hay conectividad inicial a $REMOTE_IP:$LDAP_PORT"
    exit 1
fi

ensure_directory "$(dirname "$RULES_FILE")"
printf '%s\n%s\n' "${output_rule[*]}" "${input_rule[*]}" >> "$RULES_FILE"
"${output_rule[@]}"
RULES_APPLIED=true
"${input_rule[@]}"

if timeout 2 bash -c "</dev/tcp/$REMOTE_IP/$LDAP_PORT" >/dev/null 2>&1; then
    print_error "La conectividad LDAP no fue bloqueada"
    exit 1
fi

sleep_until_timeout "$PARTITION_SECONDS"
cleanup_rules

if ! timeout 3 bash -c "</dev/tcp/$REMOTE_IP/$LDAP_PORT" >/dev/null 2>&1; then
    print_error "La conectividad LDAP no se restauro"
    exit 1
fi

print_ok "Particion LDAP aplicada y restaurada de forma segura"
