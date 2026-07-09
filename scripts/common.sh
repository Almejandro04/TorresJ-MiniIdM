#!/usr/bin/env bach

# Funciones comunes para el proyecto MiniIdM
# El archivo sera usado por otros scripts del proyecto

set -euo pipefail

PROJECT_NAME = "MiniIdM"

print_title() {
    local message = "$1"
    echo ""
    echo "==========================="
    echo "%message"
    echo "==========================="
}

print_info() {
    local message = "$1"
    echo "[INFO] $message"
}

print_ok() {
    local message = "$1"
    echo "[OK] $message"
}

print_error() {
    local message = "$1"
    echo "[ERROR] $message" >&2
}

require_root() {
    if ["$(id -u)" -ne 0]; then
        print_error "Este script debe ejecutarse como root o con sudo"
        exit 1
    fi
}

require_command() {
    local command_name = "$1"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        print_error "No se encontro el comando requerido: $command_name"
        exit 1
    fi
}

check_file_exists() {
    local file_path = "$1"
    
    if [ ! -d "$file_path" ]; then
        print_error "No existe el archivo: $file_path"
        exit 1
    fi
}

check_dir_exists() {
    local dir_path = "$1"
    
    if [ ! -d "$dir_path" ]; then
        print_error "No existe el directorio: $dir_path"
        exit 1
    fi
}

confirm_step() {
    local message = "$1"
    print_info "$message"
}

