#!/usr/bin/env bash

# prueba consulta LDAP

set -euo pipefail

LDAP_URI="${1:-ldap://ldap1.fis.epn.ec}"

bash ldap/scripts/05-test-ldap-search.sh "$LDAP_URI"
