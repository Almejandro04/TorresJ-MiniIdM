#!/usr/bin/env bash

# pruebas laboratorio

set -euo pipefail

RUN_MODE="${1:-list}"

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

bash tests/ldap/test-ldap-search.sh
bash tests/ldap/test-ldaps.sh
bash tests/kerberos/test-kinit.sh
bash tests/kerberos/test-service-ticket.sh
bash tests/tls/test-openssl-s-client.sh
bash tests/ha/test-throughput.sh
