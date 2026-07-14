#!/usr/bin/env bash

# compara latencia LDAP sin TLS y LDAPS

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/scripts/common-experiments.sh"

LDAP_URI="${LDAP_URI:-ldap://ldap1.fis.epn.ec}"
LDAPS_URI="${LDAPS_URI:-ldaps://ldap1.fis.epn.ec}"
LDAP_BASE_DN="${LDAP_BASE_DN:-dc=fis,dc=epn,dc=ec}"
CA_CERT="${CA_CERT:-$PROJECT_DIR/pki/certs/ca-root.crt}"
TRIALS="${TRIALS:-5}"
QUERY_TIMEOUT_SECONDS="${QUERY_TIMEOUT_SECONDS:-5}"
RESULT_FILE="$PROJECT_DIR/results/experiments/ldap-tls-overhead.csv"

print_title "Medicion de overhead TLS LDAP"

require_command ldapsearch
require_command timeout
require_positive_integer "TRIALS" "$TRIALS"
require_positive_integer "QUERY_TIMEOUT_SECONDS" "$QUERY_TIMEOUT_SECONDS"
check_file_exists "$CA_CERT"
initialize_csv "$RESULT_FILE" "protocol,trial,latency_ms,result"

measure_protocol() {
    local protocol="$1"
    local uri="$2"
    local trial start_ms end_ms latency_ms result
    local -a latencies=()

    for ((trial = 1; trial <= TRIALS; trial++)); do
        start_ms="$(monotonic_milliseconds)"
        if [ "$protocol" = "ldaps" ]; then
            if run_with_timeout "$QUERY_TIMEOUT_SECONDS" ldapsearch -x -LLL -H "$uri" -o "TLS_CACERT=$CA_CERT" -b "$LDAP_BASE_DN" "(uid=jperez)" uid >/dev/null 2>&1; then
                result="ok"
            else
                result="failed"
            fi
        elif run_with_timeout "$QUERY_TIMEOUT_SECONDS" ldapsearch -x -LLL -H "$uri" -b "$LDAP_BASE_DN" "(uid=jperez)" uid >/dev/null 2>&1; then
            result="ok"
        else
            result="failed"
        fi
        end_ms="$(monotonic_milliseconds)"
        latency_ms="$((end_ms - start_ms))"

        if [ "$latency_ms" -lt 0 ] || [ "$latency_ms" -gt "$((QUERY_TIMEOUT_SECONDS * 1000))" ]; then
            latency_ms="$((QUERY_TIMEOUT_SECONDS * 1000))"
            result="failed"
        fi

        append_csv_row "$RESULT_FILE" "$protocol" "$trial" "$latency_ms" "$result"
        if [ "$result" = "ok" ]; then
            latencies+=("$latency_ms")
        fi
    done

    if [ "${#latencies[@]}" -gt 0 ]; then
        print_info "$protocol: $(basic_statistics "${latencies[@]}") ms"
    else
        print_error "$protocol: no hubo consultas exitosas"
    fi
}

measure_protocol "ldap" "$LDAP_URI"
measure_protocol "ldaps" "$LDAPS_URI"

print_ok "Resultados guardados en $RESULT_FILE"
