#!/usr/bin/env bash

# utilidades para experimentos y pruebas de fallos MiniIdM

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

monotonic_milliseconds() {
    require_command awk
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

require_nonempty() {
    local value_name="$1"
    local value="$2"

    if [ -z "$value" ]; then
        print_error "Debe definir $value_name"
        return 1
    fi
}

require_file_not_world_readable() {
    local file_path="$1"
    local file_mode

    check_file_exists "$file_path"
    require_command stat
    file_mode="$(stat -c '%a' "$file_path")"

    if [ $((8#$file_mode & 4)) -ne 0 ]; then
        print_error "El archivo no debe ser legible por otros usuarios: $file_path"
        return 1
    fi
}

ensure_directory() {
    local directory_path="$1"

    require_command mkdir

    if [ -z "$directory_path" ] || [ "$directory_path" = "/" ] || [ "$directory_path" = "." ]; then
        print_error "Ruta de directorio no valida: $directory_path"
        return 1
    fi

    mkdir -p -m 0750 "$directory_path"
}

safe_temp_file() {
    local template="${1:-${TMPDIR:-/tmp}/miniidm.XXXXXX}"

    require_command mktemp
    mktemp "$template"
}

safe_temp_dir() {
    local template="${1:-${TMPDIR:-/tmp}/miniidm.XXXXXX}"

    require_command mktemp
    mktemp -d "$template"
}

safe_remove_temp_file() {
    local path="$1"

    require_command rm

    case "$path" in
        ''|/|.)
            print_error "Ruta temporal no valida para limpieza"
            return 1
            ;;
    esac

    if [ -e "$path" ]; then
        rm -f -- "$path"
    fi
}

safe_remove_temp_dir() {
    local path="$1"
    local temp_root="${TMPDIR:-/tmp}"

    require_command rm

    case "$path" in
        "$temp_root"/*) ;;
        *)
            print_error "Solo se pueden eliminar directorios temporales bajo $temp_root"
            return 1
            ;;
    esac

    if [ -d "$path" ]; then
        rm -rf -- "$path"
    fi
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

    require_command timeout
    require_positive_integer "timeout" "$timeout_seconds"
    timeout "$timeout_seconds" "$@"
}

tcp_check() {
    local host_name="$1"
    local port_number="$2"
    local timeout_seconds="${3:-3}"

    require_positive_integer "puerto" "$port_number"
    run_with_timeout "$timeout_seconds" bash -c "</dev/tcp/$host_name/$port_number" >/dev/null 2>&1
}

wait_for_new_main_pid() {
    local service_name="$1"
    local old_main_pid="$2"
    local timeout_seconds="$3"
    local deadline_ms current_pid service_state

    require_command systemctl
    require_positive_integer "timeout" "$timeout_seconds"
    deadline_ms="$(( $(monotonic_milliseconds) + timeout_seconds * 1000 ))"

    while [ "$(monotonic_milliseconds)" -lt "$deadline_ms" ]; do
        current_pid="$(systemctl show --property MainPID --value "$service_name")"
        service_state="$(systemctl is-active "$service_name" 2>/dev/null || true)"

        if [ "$service_state" = "active" ] && [ "$current_pid" -gt 0 ] && [ "$current_pid" != "$old_main_pid" ]; then
            printf '%s\n' "$current_pid"
            return 0
        fi
        sleep 0.1
    done

    print_error "No aparecio un MainPID nuevo para $service_name antes del timeout"
    return 1
}

median() {
    if [ "$#" -eq 0 ]; then
        print_error "No hay valores para calcular la mediana"
        return 1
    fi

    require_command sort
    require_command awk
    printf '%s\n' "$@" | sort -n | awk '
        { values[NR] = $1 }
        END {
            if (NR % 2 == 1) {
                printf "%.2f", values[(NR + 1) / 2]
            } else {
                printf "%.2f", (values[NR / 2] + values[NR / 2 + 1]) / 2
            }
        }
    '
}

basic_statistics() {
    if [ "$#" -eq 0 ]; then
        print_error "No hay valores para calcular estadisticas"
        return 1
    fi

    local median_value
    median_value="$(median "$@")"
    printf '%s\n' "$@" | awk -v median="$median_value" '
        NR == 1 { min = $1; max = $1 }
        { sum += $1; if ($1 < min) min = $1; if ($1 > max) max = $1 }
        END { printf "avg=%.2f,min=%d,max=%d,median=%s", sum / NR, min, max, median }
    '
}
