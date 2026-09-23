local bindings = {
  { "SUPER + SHIFT + CTRL + C", "Config", "~/bin/menu-config" },
  { "SUPER + ALT + V", "Audio Menu", "~/bin/menu-audio" },
  { "SUPER + ALT + N", "Share Menu", "~/bin/menu-share" },
  { "SUPER + ALT + W", "Workspace Axis Menu", "~/bin/menu-workspace-axis" },
  { "CTRL + ALT + SPACE", "Next Background", "~/bin/bg-next" },
  { "CTRL + ALT + SHIFT + SPACE", "Previous Background", "~/bin/bg-prev" },
  { "SUPER + CTRL + SPACE", "Toggle Background Slideshow", "~/bin/bg-toggle-slideshow" },
  { "SUPER + SPACE", "App Launcher", "~/bin/menu-apps" },
  { "SUPER + SHIFT + L", "Lock Screen", "$HOME/bin/system-lock --wait" },
  { "SUPER + ALT + F", "File Menu", "~/bin/menu-files" },
  { "SUPER + ALT + C", "Clipboard Menu", "~/bin/menu-clipboard" },
  { "SUPER + SHIFT + Z", "Toggle Zen Mode", "~/bin/toggle-zen-mode" },
  { "SUPER + ALT + J", "Tools Menu", "~/bin/menu-tools" },
  { "SUPER + SHIFT + ALT + B", "Border Menu", "~/bin/menu-border" },
  { "SUPER + ALT + I", "Install Menu", "~/bin/menu-install" },
  { "SUPER + ALT + SHIFT + SPACE", "Live Background", "~/bin/bg-live" },
  { "SUPER + CTRL + ALT + SPACE", "Set Background", "~/bin/bg-set" },
  { "SUPER + ALT + L", "Layout Menu", "~/bin/menu-layout" },
  { "SUPER + ALT + SHIFT + C", "Color Converter", "~/bin/menu-color-converter" },
  { "SUPER + SHIFT + ALT + T", "Style Menu", "~/bin/menu-style" },
  { "SUPER + S", "Quick Region Screenshot", "~/bin/launch-screenshot-clipboard" },
  { "SUPER + SHIFT + S", "Quick Active Monitor Screenshot", "~/bin/launch-screenshot-active-monitor-clipboard" },
  { "SUPER + ALT + S", "Screenshot Menu", "~/bin/menu-screenshot" },
  { "SUPER + SHIFT + ALT + S", "Capture Menu", "~/bin/menu-capture" },
  { "SUPER + ALT + E", "Emoji Menu", "~/bin/menu-emojis" },
  { "SUPER + ALT + U", "Unicode Menu", "~/bin/menu-unicode" },
  { "SUPER + SHIFT + ALT + P", "Terminal Prompt Menu", "~/bin/menu-starship" },
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

hl.unbind("SUPER + SPACE")

local mode_owned_keys = {
  "SUPER + SHIFT + CTRL + C",
  "SUPER + ALT + V",
  "SUPER + ALT + N",
  "SUPER + ALT + W",
  "CTRL + ALT + SPACE",
  "CTRL + ALT + SHIFT + SPACE",
  "SUPER + CTRL + SPACE",
}

for _, key in ipairs(mode_owned_keys) do
  hl.unbind(key)
end

for _, binding in ipairs(bindings) do
  hl.bind(binding[1], hl.dsp.exec_cmd(binding[3]), { description = binding[2] })
end

hl.bind("Print", hl.dsp.exec_cmd("~/bin/launch-screenshot-active-monitor-clipboard"), { description = "Quick Active Monitor Screenshot" })

local volume_bindings = {
  { "XF86AudioRaiseVolume", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume +1" },
  { "XF86AudioLowerVolume", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume -1" },
  { "SUPER + XF86AudioRaiseVolume", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume +5" },
  { "SUPER + XF86AudioLowerVolume", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume -5" },
  { "XF86AudioMute", "~/bin/knob-press -- ~/bin/menu-audio" },
  { "XF86AudioMute", "~/bin/knob-release", true },
}

for _, binding in ipairs(volume_bindings) do
  hl.bind(binding[1], hl.dsp.exec_cmd(binding[2]), { locked = true, release = binding[3] or false })
end
