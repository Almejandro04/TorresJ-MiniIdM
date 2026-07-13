#!/usr/bin/env bash

# prueba TLS web

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

WEB_HOST="${1:-web.fis.epn.ec}"
WEB_PORT="${2:-443}"
CA_CERT="$PROJECT_DIR/pki/certs/ca-root.crt"

print_title "Prueba HTTPS"

require_command openssl
check_file_exists "$CA_CERT"

openssl s_client -connect "$WEB_HOST:$WEB_PORT" -servername "$WEB_HOST" -CAfile "$CA_CERT" -verify_return_error </dev/null

print_ok "TLS web verificado"
