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

LDAP_PORT="${LDAP_PORT:-636}"
PARTITION_SECONDS="${PARTITION_SECONDS:-10}"
TOTAL_TIMEOUT_SECONDS="${TOTAL_TIMEOUT_SECONDS:-30}"
LDAP_BASE_DN="${LDAP_BASE_DN:-dc=fis,dc=epn,dc=ec}"
LDAP_FILTER="${LDAP_FILTER:-(uid=jperez)}"
CA_CERT="${CA_CERT:-$PROJECT_DIR/pki/certs/ca-root.crt}"
HAPROXY_URI="${HAPROXY_URI:-ldaps://ldap.fis.epn.edu.ec:1636}"
HAPROXY_DURING_CHECK="${HAPROXY_DURING_CHECK:-true}"
RESULT_FILE="$PROJECT_DIR/results/faults/network-partition.csv"
RULES_FILE="$PROJECT_DIR/results/faults/network-partition-rules.txt"
OUTPUT_RULE_APPLIED=false
INPUT_RULE_APPLIED=false

print_title "Prueba de particion de red LDAP"

require_command hostname
require_command iptables
require_command timeout
require_command ldapsearch
require_command date
require_positive_integer "PARTITION_SECONDS" "$PARTITION_SECONDS"
require_positive_integer "TOTAL_TIMEOUT_SECONDS" "$TOTAL_TIMEOUT_SECONDS"
check_file_exists "$CA_CERT"

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

if [ "$TOTAL_TIMEOUT_SECONDS" -lt "$((PARTITION_SECONDS + 10))" ]; then
    print_error "TOTAL_TIMEOUT_SECONDS debe dejar al menos 10 s para verificaciones y restauracion"
    exit 1
fi

LOCAL_HOST="$(hostname -s)"
case "$LOCAL_HOST" in
    idm1)
        EXPECTED_REMOTE_IP="192.168.56.11"
        REMOTE_HOST="ldap2.fis.epn.ec"
        ;;
    idm2)
        EXPECTED_REMOTE_IP="192.168.56.10"
        REMOTE_HOST="ldap1.fis.epn.ec"
        ;;
    *)
        print_error "Esta prueba solo se permite en idm1 o idm2"
        exit 1
        ;;
esac

REMOTE_IP="${REMOTE_IP:-$EXPECTED_REMOTE_IP}"
if [ "$REMOTE_IP" != "$EXPECTED_REMOTE_IP" ]; then
    print_error "REMOTE_IP debe ser $EXPECTED_REMOTE_IP para limitar la particion a las dos VM"
    exit 1
fi

if [ "$LDAP_PORT" = "636" ]; then
    REMOTE_LDAP_URI="${REMOTE_LDAP_URI:-ldaps://$REMOTE_HOST:636}"
else
    REMOTE_LDAP_URI="${REMOTE_LDAP_URI:-ldap://$REMOTE_HOST:389}"
fi

RULE_COMMENT="miniidm-ldap-partition-$$"
output_rule=(iptables -I OUTPUT -p tcp -d "$REMOTE_IP" --dport "$LDAP_PORT" -m comment --comment "$RULE_COMMENT" -j DROP)
input_rule=(iptables -I INPUT -p tcp -s "$REMOTE_IP" --sport "$LDAP_PORT" -m comment --comment "$RULE_COMMENT" -j DROP)

ldap_check() {
    local uri="$1"

    if [[ "$uri" = ldaps://* ]]; then
        run_with_timeout 3 ldapsearch -x -LLL -H "$uri" -o "TLS_CACERT=$CA_CERT" -b "$LDAP_BASE_DN" "$LDAP_FILTER" uid >/dev/null 2>&1
    else
        run_with_timeout 3 ldapsearch -x -LLL -H "$uri" -b "$LDAP_BASE_DN" "$LDAP_FILTER" uid >/dev/null 2>&1
    fi
}

if [ "$APPLY" = false ]; then
    print_info "Dry-run: se verificaria LDAP directo en $REMOTE_LDAP_URI y TCP $REMOTE_IP:$LDAP_PORT"
    print_info "Regla propuesta: ${output_rule[*]}"
    print_info "Regla propuesta: ${input_rule[*]}"
    print_info "La restauracion ocurriria antes de $TOTAL_TIMEOUT_SECONDS s"
    exit 0
fi

require_root

cleanup_rules() {
    if [ "$INPUT_RULE_APPLIED" = true ]; then
        iptables -D INPUT -p tcp -s "$REMOTE_IP" --sport "$LDAP_PORT" -m comment --comment "$RULE_COMMENT" -j DROP || print_error "No se pudo eliminar la regla INPUT MiniIdM"
        INPUT_RULE_APPLIED=false
    fi
    if [ "$OUTPUT_RULE_APPLIED" = true ]; then
        iptables -D OUTPUT -p tcp -d "$REMOTE_IP" --dport "$LDAP_PORT" -m comment --comment "$RULE_COMMENT" -j DROP || print_error "No se pudo eliminar la regla OUTPUT MiniIdM"
        OUTPUT_RULE_APPLIED=false
    fi
}

trap cleanup_rules EXIT
initialize_csv "$RESULT_FILE" "timestamp,node,remote_ip,port,duration_seconds,blocked,recovered,ldap_before,ldap_during,ldap_after,result"

started_ms="$(monotonic_milliseconds)"
safety_deadline_ms="$((started_ms + TOTAL_TIMEOUT_SECONDS * 1000))"

ensure_within_safety_timeout() {
    if [ "$(monotonic_milliseconds)" -ge "$safety_deadline_ms" ]; then
        print_error "Se alcanzo el timeout total de seguridad"
        return 1
    fi
}

if ! tcp_check "$REMOTE_IP" "$LDAP_PORT" 3 || ! ldap_check "$REMOTE_LDAP_URI"; then
    print_error "Fallo la conectividad LDAP inicial hacia $REMOTE_LDAP_URI"
    exit 1
fi
ldap_before=1

ensure_directory "$(dirname "$RULES_FILE")"
"${output_rule[@]}"
OUTPUT_RULE_APPLIED=true
printf '%s\n' "${output_rule[*]}" >> "$RULES_FILE"
"${input_rule[@]}"
INPUT_RULE_APPLIED=true
printf '%s\n' "${input_rule[*]}" >> "$RULES_FILE"

ensure_within_safety_timeout
if tcp_check "$REMOTE_IP" "$LDAP_PORT" 2; then
    blocked=0
else
    blocked=1
fi
if ldap_check "$REMOTE_LDAP_URI"; then
    ldap_during=1
else
    ldap_during=0
fi

if [ "$LOCAL_HOST" = "idm1" ] && [ "$HAPROXY_DURING_CHECK" = "true" ]; then
    if ldap_check "$HAPROXY_URI"; then
        print_info "HAProxy continuo respondiendo durante la particion"
    else
        print_error "HAProxy no respondio durante la particion; se conserva como observacion"
    fi
fi

ensure_within_safety_timeout
sleep "$PARTITION_SECONDS"
cleanup_rules

ensure_within_safety_timeout
if tcp_check "$REMOTE_IP" "$LDAP_PORT" 3; then
    recovered=1
else
    recovered=0
fi
if ldap_check "$REMOTE_LDAP_URI"; then
    ldap_after=1
else
    ldap_after=0
fi

if [ "$blocked" -eq 1 ] && [ "$recovered" -eq 1 ] && [ "$ldap_before" -eq 1 ] && [ "$ldap_during" -eq 0 ] && [ "$ldap_after" -eq 1 ]; then
    result="ok"
else
    result="verification_failed"
fi

append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$LOCAL_HOST" "$REMOTE_IP" "$LDAP_PORT" "$PARTITION_SECONDS" "$blocked" "$recovered" "$ldap_before" "$ldap_during" "$ldap_after" "$result"
if [ "$result" != "ok" ]; then
    print_error "La particion LDAP no cumplio todas las verificaciones"
    exit 1
fi

print_ok "Particion LDAP aplicada, medida y restaurada"
