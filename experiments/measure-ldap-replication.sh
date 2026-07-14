#!/usr/bin/env bash

# mide el retardo de replicacion LDAP de ldap1 a ldap2

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/scripts/common-experiments.sh"

MASTER_URI="${MASTER_URI:-ldap://ldap1.fis.epn.ec}"
REPLICA_URI="${REPLICA_URI:-ldap://ldap2.fis.epn.ec}"
LDAP_BASE_DN="${LDAP_BASE_DN:-dc=fis,dc=epn,dc=ec}"
LDAP_BIND_DN="${LDAP_BIND_DN:-}"
LDAP_BIND_PASSWORD_FILE="${LDAP_BIND_PASSWORD_FILE:-}"
TRIALS="${TRIALS:-3}"
REPLICATION_TIMEOUT_SECONDS="${REPLICATION_TIMEOUT_SECONDS:-30}"
RESULT_FILE="$PROJECT_DIR/results/experiments/ldap-replication.csv"
CURRENT_DN=""
TEMP_LDIF=""

print_title "Medicion de replicacion LDAP"

require_command ldapadd
require_command ldapdelete
require_command ldapsearch
require_command mktemp
require_command date
require_positive_integer "TRIALS" "$TRIALS"
require_positive_integer "REPLICATION_TIMEOUT_SECONDS" "$REPLICATION_TIMEOUT_SECONDS"

if [ -z "$LDAP_BIND_DN" ]; then
    print_error "Defina LDAP_BIND_DN; no se usan credenciales hardcodeadas"
    exit 1
fi

if [ -n "$LDAP_BIND_PASSWORD_FILE" ]; then
    check_file_exists "$LDAP_BIND_PASSWORD_FILE"
    LDAP_AUTH_ARGS=(-x -D "$LDAP_BIND_DN" -y "$LDAP_BIND_PASSWORD_FILE")
else
    LDAP_AUTH_ARGS=(-x -D "$LDAP_BIND_DN" -W)
fi

cleanup_entry() {
    if [ -n "$CURRENT_DN" ]; then
        print_info "Eliminando entrada LDAP temporal: $CURRENT_DN"
        ldapdelete -H "$MASTER_URI" "${LDAP_AUTH_ARGS[@]}" "$CURRENT_DN" >/dev/null 2>&1 || print_error "No se pudo eliminar la entrada temporal $CURRENT_DN"
        CURRENT_DN=""
    fi

    if [ -n "$TEMP_LDIF" ]; then
        rm -f "$TEMP_LDIF"
    fi
}

trap cleanup_entry EXIT

initialize_csv "$RESULT_FILE" "trial,start_timestamp,replication_ms,result"

for ((trial = 1; trial <= TRIALS; trial++)); do
    uid="replication-${trial}-$(date +%s)-$$"
    CURRENT_DN="uid=$uid,ou=People,$LDAP_BASE_DN"
    TEMP_LDIF="$(mktemp)"

    cat > "$TEMP_LDIF" <<EOF
dn: $CURRENT_DN
objectClass: inetOrgPerson
cn: $uid
sn: experiment
uid: $uid
EOF

    print_info "Prueba $trial/$TRIALS: creando $CURRENT_DN"
    ldapadd -H "$MASTER_URI" "${LDAP_AUTH_ARGS[@]}" -f "$TEMP_LDIF" >/dev/null
    start_timestamp="$(date -Iseconds)"
    start_ms="$(monotonic_milliseconds)"
    deadline_ms="$((start_ms + REPLICATION_TIMEOUT_SECONDS * 1000))"
    result="timeout"
    replication_ms="$((REPLICATION_TIMEOUT_SECONDS * 1000))"

    while [ "$(monotonic_milliseconds)" -lt "$deadline_ms" ]; do
        if ldapsearch -x -LLL -H "$REPLICA_URI" -b "$LDAP_BASE_DN" "(uid=$uid)" uid 2>/dev/null | grep -Fqx "uid: $uid"; then
            replication_ms="$(( $(monotonic_milliseconds) - start_ms ))"
            result="ok"
            break
        fi
        sleep 0.1
    done

    append_csv_row "$RESULT_FILE" "$trial" "$start_timestamp" "$replication_ms" "$result"
    print_info "Prueba $trial: $result en ${replication_ms} ms"
    cleanup_entry
    TEMP_LDIF=""
done

print_ok "Resultados guardados en $RESULT_FILE"
