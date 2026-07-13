#!/usr/bin/env bash

# prueba TLS servicio

set -euo pipefail

HOST_NAME="${1:-web.fis.epn.ec}"
PORT_NUMBER="${2:-443}"
CA_CERT="${3:-pki/certs/ca-root.crt}"

openssl s_client -connect "$HOST_NAME:$PORT_NUMBER" -servername "$HOST_NAME" -CAfile "$CA_CERT" -verify_return_error </dev/null
