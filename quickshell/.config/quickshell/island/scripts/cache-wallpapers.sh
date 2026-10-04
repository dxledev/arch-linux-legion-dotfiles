#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(/usr/bin/dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cache_directory="${ISLAND_THUMBNAIL_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/island/wallpapers}"
exec /usr/bin/python "$script_dir/wallpaper-cache.py" --cache-directory "$cache_directory" "$@"
