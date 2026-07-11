#!/usr/bin/env bash

# Limpiar archivos temprales generados durante pruebas

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/common.sh"

print_title "Limpieza"

print_title "Directorio del proyecto: $PROJECT_DIR"

find "$PROJECT_DIR" -name "*.tmp" -type f -delete
find "$PROJECT_DIR" -name "*.log" -type f -delete
find "$PROJECT_DIR" -name "*.bak" -type f -delete

print_ok "Archivos temporales eliminados"