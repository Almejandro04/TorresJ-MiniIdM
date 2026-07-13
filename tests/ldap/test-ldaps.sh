#!/usr/bin/env bash

# prueba LDAPS

set -euo pipefail

LDAP_HOST="${1:-ldap1.fis.epn.ec}"
LDAP_PORT="${2:-636}"
CA_CERT="${3:-pki/certs/ca-root.crt}"

openssl s_client -connect "$LDAP_HOST:$LDAP_PORT" -servername "$LDAP_HOST" -CAfile "$CA_CERT" -verify_return_error </dev/null
