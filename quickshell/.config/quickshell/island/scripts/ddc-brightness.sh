#!/usr/bin/env bash
set -euo pipefail

usage() { printf 'Usage: ddc-brightness.sh dp|hdmi up|down|min [--dry-run]\n'; }
[[ $# == 2 || ( $# == 3 && "$3" == --dry-run ) ]] || { usage >&2; exit 2; }
[[ "$1" == dp || "$1" == hdmi ]] || { usage >&2; exit 2; }
[[ "$2" == up || "$2" == down || "$2" == min ]] || { usage >&2; exit 2; }
script_dir="$(cd -- "$(/usr/bin/dirname -- "${BASH_SOURCE[0]}")" && pwd)"
helper="${ISLAND_DESKTOP_BIN_DIR:-$HOME/bin}/system-brightness-$1"
[[ "$helper" == /* && -x "$helper" ]] || { printf 'Island: brightness helper unavailable: %s\n' "$helper" >&2; exit 1; }
if [[ "${3:-}" == --dry-run ]]; then printf '%s %s (Island OSD)\n' "$helper" "$2"; exit; fi
export ISLAND_BRIGHTNESS_CONNECTOR_TYPE
if [[ "$1" == dp ]]; then ISLAND_BRIGHTNESS_CONNECTOR_TYPE=DP; else ISLAND_BRIGHTNESS_CONNECTOR_TYPE=HDMI-A; fi
export PATH="$script_dir/../integration/osd:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin"
exec "$helper" "$2"
