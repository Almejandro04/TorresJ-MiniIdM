#!/usr/bin/env bash

# prueba de conmutación por error del KDC

set -euo pipefail

USER_NAME="${1:-jperez}"

bash kerberos/scripts/08-test-kdc-failover.sh "$USER_NAME"
