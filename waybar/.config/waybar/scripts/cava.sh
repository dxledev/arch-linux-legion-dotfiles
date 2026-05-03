#!/usr/bin/env bash
set -euo pipefail

readonly CONFIG_FILE="/tmp/waybar_cava_config"
readonly EMPTY_BARS="▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁"
readonly -a BARS=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

running=1
cava_pid=""
pause_start=0

write_config() {
    printf '%s\n' \
        "[general]" \
        "bars = 24" \
        "framerate = 60" \
        "autosens = 1" \
        "" \
        "[output]" \
        "method = raw" \
        "raw_target = /dev/stdout" \
        "data_format = ascii" \
        "ascii_max_range = 7" > "$CONFIG_FILE"
}

stop_cava() {
    running=0

    if [[ -n "$cava_pid" ]]; then
        kill "$cava_pid" 2>/dev/null || true
        wait "$cava_pid" 2>/dev/null || true
    fi
}

convert_to_bars() {
    local line="$1"
    local out=""
    local n=""
    local -a nums=()

    IFS=';' read -ra nums <<< "$line"

    for n in "${nums[@]}"; do
        (( n >= 0 && n <= 7 )) || n=0
        out+="${BARS[$n]}"
    done

    printf '%s\n' "$out"
}

render_line() {
    local line="$1"
    local now=0

    now="$(date +%s)"

    if [[ "$line" =~ ^(0;?)+$ ]]; then
        if (( pause_start == 0 )); then
            pause_start="$now"
        fi

        if (( now - pause_start >= 2 )); then
            printf '%s\n' "$EMPTY_BARS"
        else
            convert_to_bars "$line"
        fi

        return
    fi

    pause_start=0
    convert_to_bars "$line"
}

run_cava() {
    local fifo=""
    local temp_dir=""

    temp_dir="$(mktemp -d /tmp/waybar_cava.XXXXXX)"
    fifo="$temp_dir/output"
    mkfifo "$fifo"

    cava -p "$CONFIG_FILE" > "$fifo" &
    cava_pid="$!"

    while (( running )) && IFS= read -r line; do
        render_line "$line"
    done < "$fifo"

    rm -f "$fifo"
    rmdir "$temp_dir" 2>/dev/null || true
    wait "$cava_pid" 2>/dev/null || true
    cava_pid=""
}

trap stop_cava EXIT INT TERM

write_config

while (( running )); do
    run_cava
    (( running )) && sleep 0.2
done
