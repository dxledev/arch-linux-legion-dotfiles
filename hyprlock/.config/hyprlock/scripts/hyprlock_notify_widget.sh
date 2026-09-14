#!/bin/bash

CONFIG="$HOME/.config/hypr/hyprlock.conf"
TEXT="$1"
RANDOM_WALLPAPER_SCRIPT="$HOME/.config/hyprlock/scripts/random-wallpaper.sh"
RANDOM_WALLPAPER_LINK="/tmp/hyprlock-random-wallpaper"
DEFAULT_WALLPAPER="$HOME/.config/themes/.caelestia-use/wallpaper.png"

SAFE_TEXT=$(echo "$TEXT" | sed 's/"/\\"/g')

# Update 'NOTIFICATION' label block text
awk -v msg="$SAFE_TEXT" '
/label {/,/}/ {
    if ($0 ~ /# NOTIFICATION/) notify_block=1
}
notify_block && /text =/ {
    $0 = "text = \"" msg "\""
    notify_block=0
}
{ print }
' "$CONFIG" > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"

if ! "$RANDOM_WALLPAPER_SCRIPT" --link "$RANDOM_WALLPAPER_LINK" >/dev/null 2>&1; then
    ln -sfn -- "$DEFAULT_WALLPAPER" "$RANDOM_WALLPAPER_LINK"
fi

# Lock screen with updated message
pkill hyprlock
hyprlock &
