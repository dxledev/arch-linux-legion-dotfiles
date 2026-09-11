local bindings = {
  { "SUPER + ALT + P", "System Menu", "~/bin/menu-system" },
  { "SUPER + ALT + K", "Keybindings Menu", "~/bin/menu-keybindings" },
  { "SUPER + SHIFT + ALT + K", "Neovim Keybindings", "~/bin/menu-neovim-bindings" },
  { "SUPER + SHIFT + ALT + L", "Learn Menu", "~/bin/menu-learn" },
  { "SUPER + ALT + SPACE", "Menu", "~/bin/menu" },
  { "SUPER + ALT + T", "Theme Menu", "~/bin/menu-theme" },
  { "SUPER + SHIFT + ALT + W", "Waybar Style Menu", "~/bin/menu-waybar" },
  { "SUPER + ALT + B", "Top Bar Menu", "~/bin/menu-waybar" },
  { "SUPER + ALT + D", "Dashboard Menu", "~/bin/menu-tasks" },
  { "SUPER + SHIFT + D", "Dashboard", "~/bin/toggle-dashboard" },
  { "SUPER + SHIFT + N", "Notification Center", "~/bin/toggle-wardnc --toggle" },
  { "SUPER + SHIFT + B", "Toggle Top Bar", "~/bin/toggle-waybar" },
  { "SUPER + SHIFT + C", "Color Center", "~/bin/toggle-chromack --toggle" },
  { "SUPER + SHIFT + CTRL + W", "Reload Waybar", "~/bin/reload-waybar" },
  { "SUPER + D", "Toggle Dock", "~/bin/toggle-dock" },
  { "SUPER + SHIFT + F1", "Minimize ASUS Brightness", "~/bin/system-brightness-dp min" },
  { "SUPER + F1", "Decrease ASUS Brightness", "~/bin/system-brightness-dp down" },
  { "SUPER + F2", "Increase ASUS Brightness", "~/bin/system-brightness-dp up" },
  { "SUPER + SHIFT + F3", "Minimize Acer Brightness", "~/bin/system-brightness-hdmi min" },
  { "SUPER + F3", "Decrease Acer Brightness", "~/bin/system-brightness-hdmi down" },
  { "SUPER + F4", "Increase Acer Brightness", "~/bin/system-brightness-hdmi up" },
}

for _, binding in ipairs(bindings) do
  hl.bind(binding[1], hl.dsp.exec_cmd(binding[3]), { description = binding[2] })
end

local volume_bindings = {
  { "XF86AudioRaiseVolume", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume +1" },
  { "XF86AudioLowerVolume", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume -1" },
  { "SUPER + XF86AudioRaiseVolume", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume +5" },
  { "SUPER + XF86AudioLowerVolume", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume -5" },
  { "XF86AudioMute", "~/bin/knob-press" },
  { "XF86AudioMute", "~/bin/knob-release", true },
}

for _, binding in ipairs(volume_bindings) do
  hl.bind(binding[1], hl.dsp.exec_cmd(binding[2]), { locked = true, release = binding[3] or false })
end
