#!/usr/bin/env bash

# prueba certificado expirado

set -euo pipefail

CA_CERT="${1:-pki/certs/ca-root.crt}"
EXPIRED_CERT="${2:-pki/certs/expired.fis.epn.ec.crt}"

if openssl verify -CAfile "$CA_CERT" "$EXPIRED_CERT"; then
    echo "[ERROR] El certificado no esta expirado" >&2
    exit 1
fi

echo "[CORRECTO] Certificado expirado rechazado"
