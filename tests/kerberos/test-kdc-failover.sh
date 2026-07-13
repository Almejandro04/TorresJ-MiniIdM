#!/usr/bin/env bash

# prueba failover KDC

set -euo pipefail

USER_NAME="${1:-jperez}"

bash kerberos/scripts/08-test-kdc-failover.sh "$USER_NAME"
