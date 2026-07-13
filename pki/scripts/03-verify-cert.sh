#!/usr/bin/env bash

# verificacion certificado

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Verificacion certificado"

if [ "$#" -ne 1 ]; then
    print_error "Uso: bash pki/scripts/03-verify-cert.sh pki/certs/servidor.crt"
    exit 1
fi

CERT_PATH="$1"

cd "$PROJECT_DIR"

CA_CERT="pki/certs/ca-root.crt"

check_file_exists "$CA_CERT"
check_file_exists "$CERT_PATH"

print_info "Verificacion contra CA"
openssl verify -CAfile "$CA_CERT" "$CERT_PATH"

print_info "Informacion Certificado"
openssl x509 -in "$CERT_PATH" -noout -subject -issuer -dates

print_info "SAN del certificado"
openssl x509 -in "$CERT_PATH" -noout -text | grep -A2 "Subject Alternative Name" || true

print_ok "Fin Verificacion"
