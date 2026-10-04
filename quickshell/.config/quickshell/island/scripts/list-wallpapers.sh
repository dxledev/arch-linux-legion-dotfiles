#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(/usr/bin/dirname -- "${BASH_SOURCE[0]}")" && pwd)"
[[ $# == 0 ]] || { printf 'Usage: list-wallpapers.sh\n' >&2; exit 2; }
"$script_dir/../integration/island-theme" wallpapers | /usr/bin/jq -r '.[].path'
