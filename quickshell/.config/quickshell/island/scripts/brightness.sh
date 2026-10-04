#!/usr/bin/env bash
set -euo pipefail

[[ $# == 1 || ( $# == 2 && "$2" == --dry-run ) ]] || { printf 'Usage: brightness.sh +5%%|5%%- [--dry-run]\n' >&2; exit 2; }
[[ "$1" =~ ^(\+[0-9]{1,2}%|[0-9]{1,2}%-)$ ]] || exit 2
if [[ "${2:-}" == --dry-run ]]; then printf '/usr/bin/brightnessctl set %s\n' "$1"; exit; fi
brightnessctl_bin="${ISLAND_BRIGHTNESSCTL_BIN:-/usr/bin/brightnessctl}"
hyprctl_bin="${ISLAND_HYPRCTL_BIN:-/usr/bin/hyprctl}"
[[ "$brightnessctl_bin" == /* && -x "$brightnessctl_bin" && "$hyprctl_bin" == /* && -x "$hyprctl_bin" ]] || exit 2
"$brightnessctl_bin" set "$1" >/dev/null
level="$("$brightnessctl_bin" -m | /usr/bin/awk -F, '{gsub(/%/, "", $4); print $4}')"
script_dir="$(cd -- "$(/usr/bin/dirname -- "${BASH_SOURCE[0]}")" && pwd)"
monitor="$("$hyprctl_bin" -j monitors | /usr/bin/jq -r '[.[] | select(.name | test("^(eDP|LVDS|DSI)-"))][0].name // empty')"
[[ "$monitor" =~ ^[A-Za-z0-9._-]{1,80}$ ]] || exit 2
exec /usr/bin/bash "$script_dir/publish-brightness-osd.sh" "$level" "$monitor"
