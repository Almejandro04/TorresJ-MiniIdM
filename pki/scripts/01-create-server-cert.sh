#!/usr/bin/env bash

# Certificado de servidor firmado por la CA raiz

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Creacion Certificado Servidor"

if [ "$#" -ne 2 ]; then
    print_error "Uso: bash pki/scripts/01-create-server-cert.sh servidor.fis.epn.ec alias"
    exit 1
fi

SERVER_NAME="$1"
SERVER_ALIAS="$2"

cd "$PROJECT_DIR"

CA_KEY="pki/private/ca-root.key"
CA_CERT="pki/certs/ca-root.crt"
SERVER_TEMPLATE="pki/openssl/server-cert.cnf"

SERVER_KEY="pki/private/${SERVER_NAME}.key"
SERVER_CSR="pki/csr/${SERVER_NAME}.csr"
SERVER_CERT="pki/certs/${SERVER_NAME}.crt"
SERVER_CONFIG_TMP="pki/openssl/${SERVER_NAME}.tmp.cnf"

check_file_exists "$CA_KEY"
check_file_exists "$CA_CERT"
check_file_exists "$SERVER_TEMPLATE"

print_info "Servidor: $SERVER_NAME"
print_info "Alias: $SERVER_ALIAS"

print_info "Configuracion temporal OpenSSL"

sed \
    -e "s/SERVER_NAME_PLACEHOLDER/$SERVER_NAME/g" \
    -e "s/SERVER_ALIAS_PLACEHOLDER/$SERVER_ALIAS/g" \
    "$SERVER_TEMPLATE" > "$SERVER_CONFIG_TMP"

if [ -f "$SERVER_KEY" ]; then
    print_info "Ya existe la clave privada del servidor: $SERVER_KEY"
else
    print_info "Generada clave privada ECDSA"
    openssl ecparam -name prime256v1 -genkey -noout -out "$SERVER_KEY"
    chmod 600 "$SERVER_KEY"
fi

print_info "Generado CSR del servidor"
openssl req \
    -new \
    -key "$SERVER_KEY" \
    -out "$SERVER_CSR" \
    -config "$SERVER_CONFIG_TMP"

print_info "certificado firmado con la CA"
openssl x509 \
    -req \
    -in "$SERVER_CSR" \
    -CA "$CA_CERT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$SERVER_CERT" \
    -days 825 \
    -sha256 \
    -extensions v3_req \
    -extfile "$SERVER_CONFIG_TMP"

rm -f "$SERVER_CONFIG_TMP"

print_ok "Creacion de certificado correcta"
print_info "Clave privada: $SERVER_KEY"
print_info "CSR: $SERVER_CSR"
print_info "Certificado: $SERVER_CERT"

