#!/usr/bin/env bash

# respaldo LDAP

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

print_title "Respaldo LDAP"

BASE_DN="dc=fis,dc=epn,dc=ec"
LDAP_URI="${1:-ldap://localhost}"
BACKUP_DIR="$PROJECT_DIR/results/raw"
BACKUP_FILE="$BACKUP_DIR/ldap-backup.ldif"

mkdir -p "$BACKUP_DIR"

print_info "URI LDAP: $LDAP_URI"
print_info "Archivo destino: $BACKUP_FILE"

ldapsearch -x -H "$LDAP_URI" -b "$BASE_DN" "(objectClass=*)" > "$BACKUP_FILE"

print_ok "Respaldo LDAP generado"
