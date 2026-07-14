#!/usr/bin/env bash

# utilidades para experimentos y pruebas de fallos MiniIdM

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

monotonic_milliseconds() {
    if [ ! -r /proc/uptime ]; then
        print_error "No se encontro un reloj monotono en /proc/uptime"
        return 1
    fi

    awk '{ printf "%.0f", $1 * 1000 }' /proc/uptime
}

require_positive_integer() {
    local value_name="$1"
    local value="$2"

    case "$value" in
        ''|*[!0-9]*)
            print_error "$value_name debe ser un entero positivo"
            return 1
            ;;
    esac

    if [ "$value" -eq 0 ]; then
        print_error "$value_name debe ser mayor que cero"
        return 1
    fi
}

ensure_directory() {
    local directory_path="$1"

    mkdir -p -m 0750 "$directory_path"
}

create_secure_tempdir() {
    local template="${1:-${TMPDIR:-/tmp}/miniidm.XXXXXX}"

    mktemp -d "$template"
}

cleanup_temporary_path() {
    local path="$1"

    case "$path" in
        ''|/|.)
            print_error "Ruta temporal no valida para limpieza"
            return 1
            ;;
    esac

    rm -rf -- "$path"
}

initialize_csv() {
    local csv_file="$1"
    local csv_header="$2"

    ensure_directory "$(dirname "$csv_file")"
    if [ ! -f "$csv_file" ]; then
        printf '%s\n' "$csv_header" > "$csv_file"
    fi
}

append_csv_row() {
    local csv_file="$1"
    shift

    local field escaped_field row=""
    for field in "$@"; do
        escaped_field="${field//\"/\"\"}"
        if [ -n "$row" ]; then
            row+=','
        fi
        row+="\"$escaped_field\""
    done

    printf '%s\n' "$row" >> "$csv_file"
}

run_with_timeout() {
    local timeout_seconds="$1"
    shift

    timeout "$timeout_seconds" "$@"
}

basic_statistics() {
    if [ "$#" -eq 0 ]; then
        return 1
    fi

    printf '%s\n' "$@" | awk '
        NR == 1 { min = $1; max = $1 }
        { sum += $1; if ($1 < min) min = $1; if ($1 > max) max = $1 }
        END { printf "avg=%.2f,min=%d,max=%d", sum / NR, min, max }
    '
}

sleep_until_timeout() {
    local seconds="$1"

    require_positive_integer "timeout" "$seconds"
    sleep "$seconds"
}
