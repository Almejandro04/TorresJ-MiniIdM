#!/usr/bin/env bash

# prueba retardo replicacion

set -euo pipefail

MASTER_URI="${1:-ldap://ldap1.fis.epn.ec}"
REPLICA_URI="${2:-ldap://ldap2.fis.epn.ec}"
TEST_LDIF="${3:-ldap/ldif/05-test-user.ldif}"
BASE_DN="dc=fis,dc=epn,dc=ec"
RESULT_FILE="results/tables/ldap-replication.csv"

if grep -q "REPLACE_WITH\|PLACEHOLDER" "$TEST_LDIF"; then
    echo "[ERROR] Reemplazar el hash de $TEST_LDIF antes de ejecutar" >&2
    exit 1
fi

start_time="$(date +%s%3N)"
ldapadd -x -H "$MASTER_URI" -D "cn=admin,$BASE_DN" -W -f "$TEST_LDIF"

while ! ldapsearch -x -LLL -H "$REPLICA_URI" -b "$BASE_DN" "(uid=testreplica)" uid | grep -q "^uid: testreplica$"; do
    sleep 1
done

end_time="$(date +%s%3N)"
delay_ms="$((end_time - start_time))"
printf '%s,%s,%s,%s,%s,%s\n' "$(date -Iseconds)" "$MASTER_URI" "$REPLICA_URI" testreplica "$delay_ms" ok >> "$RESULT_FILE"
echo "[OK] Retardo de replicacion: $delay_ms ms"
