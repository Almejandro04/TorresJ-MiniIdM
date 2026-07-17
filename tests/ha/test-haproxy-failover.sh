#!/usr/bin/env bash

# prueba de conmutación por error de HAProxy

set -euo pipefail

bash ha/scripts/03-test-ldap-failover.sh "${1:-ldaps://ldap.fis.epn.edu.ec:1636}"
