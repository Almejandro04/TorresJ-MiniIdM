#!/usr/bin/env bash

# mide el retardo de replicacion LDAP de ldap1 a ldap2

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/scripts/common-experiments.sh"

MASTER_URI="${MASTER_URI:-ldap://ldap1.fis.epn.ec}"
REPLICA_URI="${REPLICA_URI:-ldap://ldap2.fis.epn.ec}"
LDAP_BASE_DN="${LDAP_BASE_DN:-dc=fis,dc=epn,dc=ec}"
LDAP_USERS_OU="${LDAP_USERS_OU:-ou=users}"
LDAP_BIND_DN="${LDAP_BIND_DN:-}"
LDAP_BIND_PASSWORD_FILE="${LDAP_BIND_PASSWORD_FILE:-}"
TRIALS="${TRIALS:-3}"
REPLICATION_TIMEOUT_SECONDS="${REPLICATION_TIMEOUT_SECONDS:-30}"
LDAP_QUERY_TIMEOUT_SECONDS="${LDAP_QUERY_TIMEOUT_SECONDS:-5}"
RESULT_FILE="$PROJECT_DIR/results/experiments/ldap-replication.csv"
CLEANUP_LOG="$PROJECT_DIR/results/experiments/ldap-replication-cleanup.log"
CURRENT_DN=""
TEMP_LDIF=""
ENTRY_CREATED=false

print_title "Medicion de replicacion LDAP"

require_command ldapadd
require_command ldapdelete
require_command ldapsearch
require_command date
require_positive_integer "TRIALS" "$TRIALS"
require_positive_integer "REPLICATION_TIMEOUT_SECONDS" "$REPLICATION_TIMEOUT_SECONDS"
require_positive_integer "LDAP_QUERY_TIMEOUT_SECONDS" "$LDAP_QUERY_TIMEOUT_SECONDS"

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
    if [ "$ENTRY_CREATED" = true ] && [ -n "$CURRENT_DN" ]; then
        print_info "Eliminando entrada LDAP temporal: $CURRENT_DN"
        if ! ldapdelete -H "$MASTER_URI" "${LDAP_AUTH_ARGS[@]}" "$CURRENT_DN" >/dev/null 2>&1; then
            ensure_directory "$(dirname "$CLEANUP_LOG")"
            printf '%s %s\n' "$(date -Iseconds)" "$CURRENT_DN" >> "$CLEANUP_LOG"
            print_error "No se pudo eliminar la entrada temporal; DN registrado en $CLEANUP_LOG"
        fi
        ENTRY_CREATED=false
        CURRENT_DN=""
    fi

    if [ -n "$TEMP_LDIF" ]; then
        safe_remove_temp_file "$TEMP_LDIF"
        TEMP_LDIF=""
    fi
}

trap cleanup_entry EXIT

initialize_csv "$RESULT_FILE" "trial,start_timestamp,replication_ms,result"
LDAP_USERS_DN="$LDAP_USERS_OU,$LDAP_BASE_DN"

if ! run_with_timeout "$LDAP_QUERY_TIMEOUT_SECONDS" ldapsearch -x -LLL -H "$MASTER_URI" -b "$LDAP_USERS_DN" -s base "(objectClass=*)" dn 2>/dev/null | grep -Fqx "dn: $LDAP_USERS_DN"; then
    print_error "No existe o no es consultable la OU de usuarios: $LDAP_USERS_DN"
    exit 1
fi

for ((trial = 1; trial <= TRIALS; trial++)); do
    uid="replication-${trial}-$(date +%s)-$$"
    CURRENT_DN="uid=$uid,$LDAP_USERS_DN"
    TEMP_LDIF="$(safe_temp_file)"

    cat > "$TEMP_LDIF" <<EOF
dn: $CURRENT_DN
objectClass: inetOrgPerson
cn: $uid
sn: experiment
uid: $uid
EOF

    print_info "Prueba $trial/$TRIALS: creando $CURRENT_DN"
    ldapadd -H "$MASTER_URI" "${LDAP_AUTH_ARGS[@]}" -f "$TEMP_LDIF" >/dev/null
    ENTRY_CREATED=true
    start_timestamp="$(date -Iseconds)"
    start_ms="$(monotonic_milliseconds)"
    deadline_ms="$((start_ms + REPLICATION_TIMEOUT_SECONDS * 1000))"
    result="timeout"
    replication_ms="$((REPLICATION_TIMEOUT_SECONDS * 1000))"

    while [ "$(monotonic_milliseconds)" -lt "$deadline_ms" ]; do
        if run_with_timeout "$LDAP_QUERY_TIMEOUT_SECONDS" ldapsearch -x -LLL -H "$REPLICA_URI" -b "$LDAP_USERS_DN" "(uid=$uid)" uid 2>/dev/null | grep -Fqx "uid: $uid"; then
            replication_ms="$(( $(monotonic_milliseconds) - start_ms ))"
            result="ok"
            break
        fi
        sleep 0.1
    done

    append_csv_row "$RESULT_FILE" "$trial" "$start_timestamp" "$replication_ms" "$result"
    print_info "Prueba $trial: $result en ${replication_ms} ms"
    cleanup_entry
done

print_ok "Resultados guardados en $RESULT_FILE"
