#!/usr/bin/env bash

# funciones comunes

set -euo pipefail

PROJECT_NAME="TorresJ-MiniIdM"

print_title() {
    local message="$1"
    printf '\n- %s -\n' "${message^^}"
}

print_info() {
    local message="$1"
    echo "[INFO] $message"
}

print_ok() {
    local message="$1"
    echo "[OK] $message"
}

print_error() {
    local message="$1"
    echo "[ERROR] $message" >&2
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_error "Este script debe ejecutarse como root o con sudo"
        exit 1
    fi
}

require_command() {
    local command_name="$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        print_error "No se encontro el comando requerido: $command_name"
        exit 1
    fi
}

check_file_exists() {
    local file_path="$1"
    
    if [ ! -f "$file_path" ]; then
        print_error "No existe el archivo: $file_path"
        exit 1
    fi
}

check_file_nonempty() {
    local file_path="$1"

    check_file_exists "$file_path"
    if [ ! -s "$file_path" ]; then
        print_error "El archivo esta vacio: $file_path"
        exit 1
    fi
}

require_keytab_principal() {
    local keytab_path="$1"
    local principal="$2"

    check_file_exists "$keytab_path"
    require_command klist

    if ! klist -k "$keytab_path" 2>/dev/null | grep -Fq -- "$principal"; then
        print_error "Falta $principal en $keytab_path"
        exit 1
    fi
}

export_keytab_principals() {
    local keytab_path="$1"
    shift

    if [ "$#" -eq 0 ]; then
        print_error "No se indicaron principals para exportar a $keytab_path"
        return 1
    fi

    local keytab_dir temporary_dir temporary_keytab principal
    keytab_dir="$(dirname "$keytab_path")"
    temporary_dir="$(mktemp -d "$keytab_dir/.keytab.XXXXXX")"
    temporary_keytab="$temporary_dir/keytab"

    if ! (
        for principal in "$@"; do
            kadmin.local -q "ktadd -norandkey -k $temporary_keytab $principal" || exit 1
        done

        chmod 0600 "$temporary_keytab"
        mv -f "$temporary_keytab" "$keytab_path"
    ); then
        rm -rf "$temporary_dir"
        return 1
    fi

    rmdir "$temporary_dir"
}

check_dir_exists() {
    local dir_path="$1"
    
    if [ ! -d "$dir_path" ]; then
        print_error "No existe el directorio: $dir_path"
        exit 1
    fi
}

confirm_step() {
    local message="$1"
    print_info "$message"
}
