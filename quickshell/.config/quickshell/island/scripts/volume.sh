#!/usr/bin/env bash
set -euo pipefail

usage() { printf 'Usage: volume.sh up|down|mute [1-20] [--dry-run]\n'; }
[[ $# -ge 1 && $# -le 3 ]] || { usage >&2; exit 2; }
action="$1"
shift
step=1
dry_run=0
if [[ "${1:-}" =~ ^[0-9]+$ ]]; then step="$1"; shift; fi
[[ "${1:-}" != --dry-run ]] || { dry_run=1; shift; }
[[ $# == 0 && "$step" -ge 1 && "$step" -le 20 ]] || { usage >&2; exit 2; }
case "$action" in
    up) args=(set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "$step%+") ;;
    down) args=(set-volume @DEFAULT_AUDIO_SINK@ "$step%-") ;;
    mute) args=(set-mute @DEFAULT_AUDIO_SINK@ toggle) ;;
    *) usage >&2; exit 2 ;;
esac
if (( dry_run )); then printf '/usr/bin/wpctl'; printf ' %q' "${args[@]}"; printf '\n'; exit; fi
/usr/bin/wpctl "${args[@]}"
value="$(/usr/bin/wpctl get-volume @DEFAULT_AUDIO_SINK@)"
if [[ "$value" == *MUTED* ]]; then level=-1; else level="$(/usr/bin/awk '{printf "%.0f", $2 * 100}' <<< "$value")"; fi
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/island/status"
/usr/bin/mkdir -p -- "$cache_dir"
printf 'volume|%s\n' "$level" > "$cache_dir/event"
