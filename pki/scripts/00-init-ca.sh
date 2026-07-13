#!/usr/bin/env bash

# inicializacion CA raiz

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Inicializacion de CA raiz"

cd "$PROJECT_DIR"

CA_KEY="pki/private/ca-root.key"
CA_CERT="pki/certs/ca-root.crt"
CA_CONFIG="pki/openssl/ca-root.cnf"

check_file_exists "$CA_CONFIG"

print_info "Creacion directorio CA"

mkdir -p pki/ca/certs
mkdir -p pki/ca/crl
mkdir -p pki/ca/newcerts
mkdir -p pki/ca/private
mkdir -p pki/certs
mkdir -p pki/private
mkdir -p pki/csr

touch pki/ca/index.txt

if [ ! -f pki/ca/serial ]; then
    echo "1000" > pki/ca/serial
fi

if [ -f "$CA_KEY" ]; then
    print_info "Ya existe la clave privada de la CA: $CA_KEY"
else
    print_info "Generando clave privada ECDSA de la CA"
    openssl ecparam -name prime256v1 -genkey -noout -out "$CA_KEY"
    chmod 600 "$CA_KEY"
fi

if [ -f "$CA_CERT" ]; then
    print_info "Ya existe el certificado de la CA : $CA_CERT"
else
    print_info "Generando certificado raiz de la CA"
    openssl req \
        -config "$CA_CONFIG" \
        -key "$CA_KEY" \
        -new \
        -x509 \
        -days 3650 \
        -sha256 \
        -extensions v3_ca \
        -out "$CA_CERT"
fi

print_ok "CA raiz creada correctamente"
print_info "Clave privada: $CA_KEY"
print_info "Certificado CA: $CA_CERT"
