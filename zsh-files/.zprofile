if [[ -z $WAYLAND_DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
  exec start-hyprland
fi


# Added by Antigravity CLI installer
export PATH="/home/dxle/.local/bin:$PATH"
