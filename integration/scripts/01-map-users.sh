#!/usr/bin/env bash

# validacion mapeo LDAP Kerberos

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$PROJECT_DIR/scripts/common.sh"

LDAP_URI="${1:-ldap://ldap1.fis.epn.ec}"
BASE_DN="dc=fis,dc=epn,dc=ec"
REALM="FIS.EPN.EC"
USERS_FILE="$PROJECT_DIR/kerberos/principals/users.txt"

print_title "Mapeo LDAP Kerberos"

require_root
require_command ldapsearch
require_command kadmin.local
check_file_exists "$USERS_FILE"

while IFS= read -r user_name; do
    [ -z "$user_name" ] && continue
    case "$user_name" in
        \#*) continue ;;
    esac

    ldapsearch -x -LLL -H "$LDAP_URI" -b "$BASE_DN" "(uid=$user_name)" uid | grep -q "^uid: $user_name$"
    kadmin.local -q "getprinc $user_name@$REALM" >/dev/null
    print_ok "Mapeo valido: $user_name -> $user_name@$REALM"
done < "$USERS_FILE"

print_ok "Mapeo LDAP Kerberos validado"
