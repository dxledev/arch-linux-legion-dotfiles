#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(/usr/bin/dirname -- "${BASH_SOURCE[0]}")" && pwd)"
[[ $# == 1 ]] || { printf 'Usage: theme.sh NAME\n' >&2; exit 2; }
exec "$script_dir/../integration/island-theme" theme "$1"
