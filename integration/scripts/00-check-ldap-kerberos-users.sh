#!/usr/bin/env bash

# validacion usuarios LDAP Kerberos

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

LDAP_URI="${1:-ldap://ldap1.fis.epn.ec}"
BASE_DN="dc=fis,dc=epn,dc=ec"
USERS_FILE="$PROJECT_DIR/kerberos/principals/users.txt"

print_title "Validacion de usuarios LDAP"

require_command ldapsearch
check_file_exists "$USERS_FILE"

while IFS= read -r user_name; do
    [ -z "$user_name" ] && continue
    case "$user_name" in
        \#*) continue ;;
    esac

    if ! ldapsearch -x -LLL -H "$LDAP_URI" -b "$BASE_DN" "(uid=$user_name)" uid | grep -q "^uid: $user_name$"; then
        print_error "Usuario LDAP no encontrado: $user_name"
        exit 1
    fi

    print_ok "Usuario LDAP encontrado: $user_name"
done < "$USERS_FILE"

print_ok "Usuarios LDAP validados"
