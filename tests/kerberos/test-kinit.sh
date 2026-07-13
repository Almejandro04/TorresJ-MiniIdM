#!/usr/bin/env bash

# prueba kinit

set -euo pipefail

USER_NAME="${1:-jperez}"

bash kerberos/scripts/05-test-kinit.sh "$USER_NAME"
