#!/usr/bin/env bash

# mide throughput LDAP mediante el frontend HAProxy

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$PROJECT_DIR/scripts/common-experiments.sh"

LDAP_URI="${LDAP_URI:-ldaps://ldap.fis.epn.edu.ec:1636}"
LDAP_BASE_DN="${LDAP_BASE_DN:-dc=fis,dc=epn,dc=ec}"
CA_CERT="${CA_CERT:-$PROJECT_DIR/pki/certs/ca-root.crt}"
REQUESTS="${REQUESTS:-100}"
CONCURRENCY="${CONCURRENCY:-5}"
QUERY_TIMEOUT_SECONDS="${QUERY_TIMEOUT_SECONDS:-5}"
RESULT_FILE="$PROJECT_DIR/results/experiments/haproxy-throughput.csv"
RESULT_DIR=""

print_title "Medicion de throughput HAProxy LDAP"

require_command ldapsearch
require_command timeout
require_command mktemp
require_command awk
require_positive_integer "REQUESTS" "$REQUESTS"
require_positive_integer "CONCURRENCY" "$CONCURRENCY"
require_positive_integer "QUERY_TIMEOUT_SECONDS" "$QUERY_TIMEOUT_SECONDS"
check_file_exists "$CA_CERT"
initialize_csv "$RESULT_FILE" "requests,concurrency,total_seconds,requests_per_second,successes,failures"

RESULT_DIR="$(create_secure_tempdir)"
trap 'cleanup_temporary_path "$RESULT_DIR"' EXIT

run_query() {
    local request_number="$1"

    if run_with_timeout "$QUERY_TIMEOUT_SECONDS" ldapsearch -x -LLL -H "$LDAP_URI" -o "TLS_CACERT=$CA_CERT" -b "$LDAP_BASE_DN" "(uid=jperez)" uid >/dev/null 2>&1; then
        printf 'success\n' > "$RESULT_DIR/$request_number"
    else
        printf 'failure\n' > "$RESULT_DIR/$request_number"
    fi
}

start_ms="$(monotonic_milliseconds)"
request_number=1
while [ "$request_number" -le "$REQUESTS" ]; do
    pids=()
    for ((slot = 0; slot < CONCURRENCY && request_number <= REQUESTS; slot++)); do
        run_query "$request_number" &
        pids+=("$!")
        request_number="$((request_number + 1))"
    done

    for pid in "${pids[@]}"; do
        wait "$pid" || true
    done
done
end_ms="$(monotonic_milliseconds)"

elapsed_ms="$((end_ms - start_ms))"
if [ "$elapsed_ms" -le 0 ]; then
    elapsed_ms=1
fi
successes=0
for result_file in "$RESULT_DIR"/*; do
    if [ -f "$result_file" ] && [ "$(<"$result_file")" = "success" ]; then
        successes="$((successes + 1))"
    fi
done
failures="$((REQUESTS - successes))"
total_seconds="$(awk -v milliseconds="$elapsed_ms" 'BEGIN { printf "%.3f", milliseconds / 1000 }')"
requests_per_second="$(awk -v requests="$REQUESTS" -v milliseconds="$elapsed_ms" 'BEGIN { printf "%.2f", requests / (milliseconds / 1000) }')"

append_csv_row "$RESULT_FILE" "$REQUESTS" "$CONCURRENCY" "$total_seconds" "$requests_per_second" "$successes" "$failures"
print_ok "Throughput: $requests_per_second req/s; exitosas=$successes, fallidas=$failures"
