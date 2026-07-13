#!/usr/bin/env bash

# certificado expirado

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Creacion certificado caducado"

cd "$PROJECT_DIR"

CA_KEY="pki/private/ca-root.key"
CA_CERT="pki/certs/ca-root.crt"
EXPIRED_CONFIG="pki/openssl/expired-cert.cnf"

EXPIRED_KEY="pki/private/expired.fis.epn.ec.key"
EXPIRED_CSR="pki/csr/expired.fis.epn.ec.csr"
EXPIRED_CERT="pki/certs/expired.fis.epn.ec.crt"

check_file_exists "$CA_KEY"
check_file_exists "$CA_CERT"
check_file_exists "$EXPIRED_CONFIG"

if [ -f "$EXPIRED_KEY" ]; then
    print_info "La clave privada caducada ya existe: $EXPIRED_KEY"
else
    print_info "Creacion Clave Privada ECDSA"
    openssl ecparam -name prime256v1 -genkey -noout -out "$EXPIRED_KEY"
    chmod 600 "$EXPIRED_KEY"
fi

print_info "CSR certificado caducado"
openssl req \
    -new \
    -key "$EXPIRED_KEY" \
    -out "$EXPIRED_CSR" \
    -config "$EXPIRED_CONFIG"

print_info "Certificado con fecha de expiracion historica"
openssl ca \
    -batch \
    -config "pki/openssl/ca-root.cnf" \
    -in "$EXPIRED_CSR" \
    -out "$EXPIRED_CERT" \
    -startdate 20200101000000Z \
    -enddate 20200102000000Z \
    -extensions v3_req \
    -extfile "$EXPIRED_CONFIG"

print_ok "Certificado creado"
print_info "Certificado: $EXPIRED_CERT"
