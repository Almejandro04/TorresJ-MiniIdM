#!/usr/bin/env bash

# instalacion Prometheus

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Instalacion monitoreo"

require_root
require_command apt-get

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y prometheus prometheus-node-exporter

print_ok "Prometheus y node exporter instalados"
