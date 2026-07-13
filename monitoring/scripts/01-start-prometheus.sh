#!/usr/bin/env bash

# configuracion Prometheus

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Configuracion Prometheus"

require_root
require_command install
require_command promtool
require_command systemctl

CONFIG_FILE="$PROJECT_DIR/monitoring/prometheus/prometheus.yml"
RULES_FILE="$PROJECT_DIR/monitoring/prometheus/rules.yml"

check_file_exists "$CONFIG_FILE"
check_file_exists "$RULES_FILE"

promtool check config "$CONFIG_FILE"
install -m 0644 -o root -g root "$CONFIG_FILE" /etc/prometheus/prometheus.yml
install -m 0644 -o root -g root "$RULES_FILE" /etc/prometheus/rules.yml
systemctl enable --now prometheus prometheus-node-exporter
systemctl restart prometheus

print_ok "Prometheus activo en puerto 9090"
