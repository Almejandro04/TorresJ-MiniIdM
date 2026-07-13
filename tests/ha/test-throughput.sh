#!/usr/bin/env bash

# prueba throughput HAProxy

set -euo pipefail

LDAP_URI="${1:-ldaps://ldap.fis.epn.edu.ec}"
REQUESTS="${2:-20}"
BASE_DN="dc=fis,dc=epn,dc=ec"
CA_CERT="pki/certs/ca-root.crt"
RESULT_FILE="results/tables/lb-throughput.csv"

start_time="$(date +%s%3N)"
for _ in $(seq 1 "$REQUESTS"); do
    ldapsearch -x -LLL -H "$LDAP_URI" -o "TLS_CACERT=$CA_CERT" -b "$BASE_DN" "(uid=jperez)" uid >/dev/null
done
end_time="$(date +%s%3N)"
elapsed_ms="$((end_time - start_time))"
throughput="$(awk -v count="$REQUESTS" -v elapsed="$elapsed_ms" 'BEGIN { if (elapsed == 0) print 0; else printf "%.2f", count / (elapsed / 1000) }')"

printf '%s,%s,%s,%s,%s,%s\n' "$(date -Iseconds)" "$LDAP_URI" "$REQUESTS" "$elapsed_ms" "$throughput" ok >> "$RESULT_FILE"
echo "[OK] Throughput: $throughput consultas por segundo"
