#!/usr/bin/env bash

# pruebas laboratorio

set -euo pipefail

RUN_MODE="${1:-list}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT_WRITER="$SCRIPT_DIR/write-result.sh"

if [ "$RUN_MODE" != "run" ]; then
    cat <<'EOF'
Pruebas disponibles:
  tests/ldap/test-ldap-search.sh
  tests/ldap/test-ldaps.sh
  tests/ldap/test-replication-delay.sh
  tests/kerberos/test-kinit.sh
  tests/kerberos/test-service-ticket.sh
  tests/kerberos/test-kdc-failover.sh
  tests/tls/test-openssl-s-client.sh
  tests/tls/test-expired-cert.sh
  tests/ha/test-haproxy-failover.sh
  tests/ha/test-throughput.sh
EOF
    exit 0
fi

run_test() {
    local test_name="$1"
    local target="$2"
    local port="$3"
    local test_script="$4"
    local start_time
    local end_time

    if ! getent hosts "$target" >/dev/null 2>&1; then
        bash "$RESULT_WRITER" "$test_name" "$target" SKIPPED 0 "DNS no disponible"
        echo "[OMITIDA] $test_name: DNS no disponible para $target"
        return 0
    fi

    if ! timeout 3 bash -c "</dev/tcp/$target/$port" >/dev/null 2>&1; then
        bash "$RESULT_WRITER" "$test_name" "$target" SKIPPED 0 "Servicio no disponible en puerto $port"
        echo "[OMITIDA] $test_name: puerto $port no disponible en $target"
        return 0
    fi

    start_time="$(date +%s%3N)"
    if bash "$test_script"; then
        end_time="$(date +%s%3N)"
        bash "$RESULT_WRITER" "$test_name" "$target" OK "$((end_time - start_time))" "Prueba completada"
        echo "[CORRECTO] $test_name"
    else
        end_time="$(date +%s%3N)"
        bash "$RESULT_WRITER" "$test_name" "$target" FAILED "$((end_time - start_time))" "La prueba devolvio error"
        echo "[FALLIDA] $test_name" >&2
    fi
}

run_test ldap-search ldap1.fis.epn.ec 389 tests/ldap/test-ldap-search.sh
run_test ldaps ldap1.fis.epn.ec 636 tests/ldap/test-ldaps.sh
run_test kerberos-kinit kdc1.fis.epn.ec 88 tests/kerberos/test-kinit.sh
run_test kerberos-service-ticket kdc1.fis.epn.ec 88 tests/kerberos/test-service-ticket.sh
run_test web-tls web.fis.epn.ec 443 tests/tls/test-openssl-s-client.sh
run_test haproxy-throughput ldap.fis.epn.edu.ec 1636 tests/ha/test-throughput.sh
