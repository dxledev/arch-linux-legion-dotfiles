#!/usr/bin/env bash

RANDOM_WALLPAPER_SCRIPT="$HOME/.config/hyprlock/scripts/random-wallpaper.sh"
RANDOM_WALLPAPER_LINK="/tmp/hyprlock-random-wallpaper"
DEFAULT_WALLPAPER="$HOME/.config/themes/.caelestia-use/wallpaper.png"

if ! "$RANDOM_WALLPAPER_SCRIPT" --link "$RANDOM_WALLPAPER_LINK" >/dev/null 2>&1; then
    ln -sfn -- "$DEFAULT_WALLPAPER" "$RANDOM_WALLPAPER_LINK"
fi

if [[ "$(playerctl -p spotify status 2>/dev/null)" == "Playing" ]]; then
    pkill glava

    # Start Glava (NOT desktop mode)
    glava &
    sleep 0.6

    # Focus Glava window
    hyprctl dispatch focuswindow class:glava
    sleep 0.1

    # Fullscreen focused window
    hyprctl dispatch fullscreen 

    # Lock screen
    hyprlock --config ~/.config/hyprlock/music.conf
else
    hyprlock
fi

pkill glava
