#!/usr/bin/env bash

# fallo certificado expirado

set -euo pipefail

TARGET_CERT="${1:-}"
TARGET_KEY="${2:-}"
EXPIRED_CERT="${3:-pki/certs/expired.fis.epn.ec.crt}"
EXPIRED_KEY="${4:-pki/private/expired.fis.epn.ec.key}"

if [ -z "$TARGET_CERT" ] || [ -z "$TARGET_KEY" ]; then
    echo "Uso: sudo bash tests/fault-injection/replace-expired-cert.sh CERTIFICADO CLAVE" >&2
    exit 1
fi

cert_mode="$(stat -c %a "$TARGET_CERT")"
cert_owner="$(stat -c %U "$TARGET_CERT")"
cert_group="$(stat -c %G "$TARGET_CERT")"
key_mode="$(stat -c %a "$TARGET_KEY")"
key_owner="$(stat -c %U "$TARGET_KEY")"
key_group="$(stat -c %G "$TARGET_KEY")"

install -m "$cert_mode" -o "$cert_owner" -g "$cert_group" "$TARGET_CERT" "$TARGET_CERT.valid"
install -m "$key_mode" -o "$key_owner" -g "$key_group" "$TARGET_KEY" "$TARGET_KEY.valid"
install -m "$cert_mode" -o "$cert_owner" -g "$cert_group" "$EXPIRED_CERT" "$TARGET_CERT"
install -m "$key_mode" -o "$key_owner" -g "$key_group" "$EXPIRED_KEY" "$TARGET_KEY"
echo "[CORRECTO] Certificado expirado instalado. Los archivos .valid se restauran despues de la prueba"
