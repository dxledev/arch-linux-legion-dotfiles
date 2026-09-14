#!/usr/bin/env bash
set -euo pipefail

wallpaper_dir="$HOME/.config/themes/.caelestia-use/wallpapers"
link_path="/tmp/hyprlock-random-wallpaper"
dry_run=0

usage() {
    echo "Usage: random-wallpaper.sh [--dir DIR] [--link PATH] [--dry-run]"
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dir)
            wallpaper_dir="${2:-}"
            shift 2
            ;;
        --link)
            link_path="${2:-}"
            shift 2
            ;;
        --dry-run)
            dry_run=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

if [ -z "${wallpaper_dir:-}" ] || [ -z "${link_path:-}" ]; then
    usage
    exit 1
fi

if [ ! -d "$wallpaper_dir" ]; then
    exit 1
fi

mapfile -d '' wallpapers < <(
    /usr/bin/find -L "$wallpaper_dir" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
        -print0
)

if [ "${#wallpapers[@]}" -eq 0 ]; then
    exit 1
fi

selected="${wallpapers[$((RANDOM % ${#wallpapers[@]}))]}"
selected_real=$(/usr/bin/readlink -f -- "$selected" 2>/dev/null || true)
if [ -n "$selected_real" ]; then
    selected="$selected_real"
fi

if [ "$dry_run" -eq 1 ]; then
    echo "$selected"
    exit 0
fi

/usr/bin/ln -sfn -- "$selected" "$link_path"
echo "$selected"
