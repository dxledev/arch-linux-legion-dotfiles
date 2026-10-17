#!/usr/bin/env bash
set -euo pipefail

[[ $# == 1 || ( $# == 2 && "$2" == --dry-run ) ]] || { printf 'Usage: brightness.sh +5%%|5%%- [--dry-run]\n' >&2; exit 2; }
[[ "$1" =~ ^(\+[0-9]{1,2}%|[0-9]{1,2}%-)$ ]] || exit 2
if [[ "${2:-}" == --dry-run ]]; then printf '/usr/bin/brightnessctl set %s\n' "$1"; exit; fi
# Whether Island runs under niri (see island/README.md, "Compositors"): ISLAND_COMPOSITOR, then the session's
# desktop name, then the compositor socket variable. Anything else keeps the Hyprland behaviour.
under_niri() {
    case "${ISLAND_COMPOSITOR:-}" in niri) return 0 ;; hyprland) return 1 ;; esac
    local desktop=":${XDG_CURRENT_DESKTOP,,}:"
    [[ "$desktop" == *:niri:* ]] && return 0
    [[ "$desktop" == *:hyprland:* ]] && return 1
    [[ -n "${NIRI_SOCKET:-}" && -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]
}
brightnessctl_bin="${ISLAND_BRIGHTNESSCTL_BIN:-/usr/bin/brightnessctl}"
hyprctl_bin="${ISLAND_HYPRCTL_BIN:-/usr/bin/hyprctl}"
niri_bin="${ISLAND_NIRI_BIN:-/usr/bin/niri}"
compositor_bin="$hyprctl_bin"
under_niri && compositor_bin="$niri_bin"
[[ "$brightnessctl_bin" == /* && -x "$brightnessctl_bin" && "$compositor_bin" == /* && -x "$compositor_bin" ]] || exit 2
"$brightnessctl_bin" set "$1" >/dev/null
level="$("$brightnessctl_bin" -m | /usr/bin/awk -F, '{gsub(/%/, "", $4); print $4}')"
script_dir="$(cd -- "$(/usr/bin/dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if under_niri; then
    monitor="$("$niri_bin" msg --json outputs | /usr/bin/jq -r '[keys[] | select(test("^(eDP|LVDS|DSI)-"))][0] // empty')"
else
    monitor="$("$hyprctl_bin" -j monitors | /usr/bin/jq -r '[.[] | select(.name | test("^(eDP|LVDS|DSI)-"))][0].name // empty')"
fi
[[ "$monitor" =~ ^[A-Za-z0-9._-]{1,80}$ ]] || exit 2
exec /usr/bin/bash "$script_dir/publish-brightness-osd.sh" "$level" "$monitor"
