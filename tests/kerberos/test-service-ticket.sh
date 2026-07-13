#!/usr/bin/env bash

# prueba ticket servicio

set -euo pipefail

SERVICE_PRINCIPAL="${1:-HTTP/web.fis.epn.ec@FIS.EPN.EC}"

kinit "${KRB_USER:-jperez}@FIS.EPN.EC"
kvno "$SERVICE_PRINCIPAL"
klist
