#!/usr/bin/env bash

# mide el rendimiento LDAP mediante un grupo de procesos de trabajo de Bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/scripts/common-experiments.sh"

LDAP_URI="${LDAP_URI:-ldaps://ldap.fis.epn.edu.ec:1636}"
LDAP_BASE_DN="${LDAP_BASE_DN:-dc=fis,dc=epn,dc=ec}"
LDAP_FILTER="${LDAP_FILTER:-(uid=jperez)}"
CA_CERT="${CA_CERT:-$PROJECT_DIR/pki/certs/ca-root.crt}"
REQUESTS="${REQUESTS:-100}"
CONCURRENCY="${CONCURRENCY:-5}"
QUERY_TIMEOUT_SECONDS="${QUERY_TIMEOUT_SECONDS:-5}"
RESULT_FILE="$PROJECT_DIR/results/experiments/haproxy-throughput.csv"
RESULT_DIR=""

print_title "Medición del rendimiento LDAP mediante HAProxy"

require_command ldapsearch
require_command timeout
require_command awk
require_positive_integer "REQUESTS" "$REQUESTS"
require_positive_integer "CONCURRENCY" "$CONCURRENCY"
require_positive_integer "QUERY_TIMEOUT_SECONDS" "$QUERY_TIMEOUT_SECONDS"
check_file_exists "$CA_CERT"
initialize_csv "$RESULT_FILE" "requests,concurrency,total_seconds,requests_per_second,average_latency_ms,successes,failures"

if ! help wait 2>/dev/null | grep -q -- '-n'; then
    print_error "Este script requiere Bash con wait -n para implementar el grupo de procesos de trabajo"
    exit 1
fi

RESULT_DIR="$(safe_temp_dir)"
trap 'safe_remove_temp_dir "$RESULT_DIR"' EXIT

run_query() {
    local request_number="$1"
    local start_ms end_ms latency_ms result

    start_ms="$(monotonic_milliseconds)"
    if run_with_timeout "$QUERY_TIMEOUT_SECONDS" ldapsearch -x -LLL -H "$LDAP_URI" -o "TLS_CACERT=$CA_CERT" -b "$LDAP_BASE_DN" "$LDAP_FILTER" uid >/dev/null 2>&1; then
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

    printf '%s,%s,%s\n' "$request_number" "$latency_ms" "$result" > "$RESULT_DIR/$request_number"
}

start_worker() {
    local request_number="$1"

    run_query "$request_number" &
}

start_ms="$(monotonic_milliseconds)"
next_request=1
active_workers=0
while [ "$next_request" -le "$REQUESTS" ] && [ "$active_workers" -lt "$CONCURRENCY" ]; do
    start_worker "$next_request"
    next_request="$((next_request + 1))"
    active_workers="$((active_workers + 1))"
done

while [ "$active_workers" -gt 0 ]; do
    wait -n || true
    active_workers="$((active_workers - 1))"

    if [ "$next_request" -le "$REQUESTS" ]; then
        start_worker "$next_request"
        next_request="$((next_request + 1))"
        active_workers="$((active_workers + 1))"
    fi
done
end_ms="$(monotonic_milliseconds)"

elapsed_ms="$((end_ms - start_ms))"
if [ "$elapsed_ms" -le 0 ]; then
    elapsed_ms=1
fi

successes=0
failures=0
latencies=()
record_count=0
for result_file in "$RESULT_DIR"/*; do
    if [ ! -f "$result_file" ]; then
        continue
    fi
    IFS=, read -r request_number latency_ms result < "$result_file"
    case "$result" in
        ok) successes="$((successes + 1))" ;;
        failed) failures="$((failures + 1))" ;;
        *)
            print_error "Resultado invalido del proceso de trabajo $request_number"
            exit 1
            ;;
    esac
    latencies+=("$latency_ms")
    record_count="$((record_count + 1))"
done

if [ "$record_count" -ne "$REQUESTS" ] || [ "$((successes + failures))" -ne "$REQUESTS" ]; then
    print_error "Los resultados de workers no coinciden con REQUESTS"
    exit 1
fi

total_seconds="$(awk -v milliseconds="$elapsed_ms" 'BEGIN { printf "%.3f", milliseconds / 1000 }')"
requests_per_second="$(awk -v requests="$REQUESTS" -v milliseconds="$elapsed_ms" 'BEGIN { printf "%.2f", requests / (milliseconds / 1000) }')"
average_latency_ms="$(printf '%s\n' "${latencies[@]}" | awk '{ sum += $1 } END { printf "%.2f", sum / NR }')"

append_csv_row "$RESULT_FILE" "$REQUESTS" "$CONCURRENCY" "$total_seconds" "$requests_per_second" "$average_latency_ms" "$successes" "$failures"
print_ok "Rendimiento: $requests_per_second solicitudes/s; latencia promedio=${average_latency_ms} ms; exitosas=$successes, fallidas=$failures"
