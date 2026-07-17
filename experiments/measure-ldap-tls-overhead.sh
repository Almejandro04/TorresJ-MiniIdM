#!/usr/bin/env bash

# compara latencia LDAP sin TLS y LDAPS con fase de calentamiento

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/scripts/common-experiments.sh"

LDAP_URI="${LDAP_URI:-ldap://ldap1.fis.epn.ec}"
LDAPS_URI="${LDAPS_URI:-ldaps://ldap1.fis.epn.ec}"
LDAP_BASE_DN="${LDAP_BASE_DN:-dc=fis,dc=epn,dc=ec}"
LDAP_FILTER="${LDAP_FILTER:-(uid=jperez)}"
CA_CERT="${CA_CERT:-$PROJECT_DIR/pki/certs/ca-root.crt}"
TRIALS="${TRIALS:-5}"
WARMUP_TRIALS="${WARMUP_TRIALS:-2}"
QUERY_TIMEOUT_SECONDS="${QUERY_TIMEOUT_SECONDS:-5}"
RESULT_FILE="$PROJECT_DIR/results/experiments/ldap-tls-overhead.csv"
SUMMARY_FILE="$PROJECT_DIR/results/experiments/ldap-tls-summary.csv"
LDAP_LATENCIES=()
LDAPS_LATENCIES=()

print_title "Medición de sobrecarga TLS LDAP"

require_command ldapsearch
require_command timeout
require_command date
require_command awk
require_positive_integer "TRIALS" "$TRIALS"
case "$WARMUP_TRIALS" in
    ''|*[!0-9]*)
        print_error "WARMUP_TRIALS debe ser cero o un entero positivo"
        exit 1
        ;;
esac
require_positive_integer "QUERY_TIMEOUT_SECONDS" "$QUERY_TIMEOUT_SECONDS"
check_file_exists "$CA_CERT"
initialize_csv "$RESULT_FILE" "timestamp,protocol,trial,latency_ms,result"
initialize_csv "$SUMMARY_FILE" "ldap_avg_ms,ldaps_avg_ms,tls_overhead_ms,tls_overhead_percent"

ldap_query() {
    local protocol="$1"
    local uri="$2"

    if [ "$protocol" = "ldaps" ]; then
        run_with_timeout "$QUERY_TIMEOUT_SECONDS" ldapsearch -x -LLL -H "$uri" -o "TLS_CACERT=$CA_CERT" -b "$LDAP_BASE_DN" "$LDAP_FILTER" uid >/dev/null 2>&1
    else
        run_with_timeout "$QUERY_TIMEOUT_SECONDS" ldapsearch -x -LLL -H "$uri" -b "$LDAP_BASE_DN" "$LDAP_FILTER" uid >/dev/null 2>&1
    fi
}

warm_up_protocol() {
    local protocol="$1"
    local uri="$2"
    local trial

    for ((trial = 1; trial <= WARMUP_TRIALS; trial++)); do
        ldap_query "$protocol" "$uri" || true
    done
}

measure_protocol() {
    local protocol="$1"
    local uri="$2"
    local trial start_ms end_ms latency_ms result

    warm_up_protocol "$protocol" "$uri"
    for ((trial = 1; trial <= TRIALS; trial++)); do
        start_ms="$(monotonic_milliseconds)"
        if ldap_query "$protocol" "$uri"; then
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

        append_csv_row "$RESULT_FILE" "$(date -Iseconds)" "$protocol" "$trial" "$latency_ms" "$result"
        if [ "$result" = "ok" ]; then
            if [ "$protocol" = "ldap" ]; then
                LDAP_LATENCIES+=("$latency_ms")
            else
                LDAPS_LATENCIES+=("$latency_ms")
            fi
        fi
    done
}

average() {
    printf '%s\n' "$@" | awk '{ sum += $1 } END { if (NR > 0) printf "%.2f", sum / NR }'
}

measure_protocol "ldap" "$LDAP_URI"
measure_protocol "ldaps" "$LDAPS_URI"

ldap_avg=""
ldaps_avg=""
if [ "${#LDAP_LATENCIES[@]}" -gt 0 ]; then
    ldap_avg="$(average "${LDAP_LATENCIES[@]}")"
    print_info "ldap: $(basic_statistics "${LDAP_LATENCIES[@]}") ms"
else
    print_error "ldap: no hubo consultas exitosas"
fi

if [ "${#LDAPS_LATENCIES[@]}" -gt 0 ]; then
    ldaps_avg="$(average "${LDAPS_LATENCIES[@]}")"
    print_info "ldaps: $(basic_statistics "${LDAPS_LATENCIES[@]}") ms"
else
    print_error "ldaps: no hubo consultas exitosas"
fi

tls_overhead_ms=""
tls_overhead_percent=""
if [ -n "$ldap_avg" ] && [ -n "$ldaps_avg" ]; then
    tls_overhead_ms="$(awk -v ldap_avg="$ldap_avg" -v ldaps_avg="$ldaps_avg" 'BEGIN { printf "%.2f", ldaps_avg - ldap_avg }')"
    if awk -v ldap_avg="$ldap_avg" 'BEGIN { exit !(ldap_avg != 0) }'; then
        tls_overhead_percent="$(awk -v ldap_avg="$ldap_avg" -v overhead="$tls_overhead_ms" 'BEGIN { printf "%.2f", overhead * 100 / ldap_avg }')"
    fi
fi

append_csv_row "$SUMMARY_FILE" "$ldap_avg" "$ldaps_avg" "$tls_overhead_ms" "$tls_overhead_percent"
print_info "tls_overhead_ms=${tls_overhead_ms:-no_disponible}, tls_overhead_percent=${tls_overhead_percent:-no_disponible}"
print_ok "Resultados guardados en $RESULT_FILE y $SUMMARY_FILE"
