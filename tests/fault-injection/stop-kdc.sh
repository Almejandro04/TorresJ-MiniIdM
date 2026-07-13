#!/usr/bin/env bash

# fallo KDC

set -euo pipefail

systemctl stop krb5-kdc
echo "[OK] Servicio krb5-kdc detenido"
