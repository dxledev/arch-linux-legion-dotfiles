local bindings = {
  { "SUPER + SHIFT + ALT + W", "Waybar Style Menu", "~/bin/menu-waybar" },
  { "SUPER + ALT + B", "Top Bar Menu", "~/bin/menu-waybar" },
  { "SUPER + ALT + D", "Dashboard Menu", "~/bin/menu-tasks" },
  { "SUPER + SHIFT + D", "Dashboard", "~/bin/toggle-dashboard" },
  { "SUPER + SHIFT + N", "Notification Center", "~/bin/toggle-wardnc --toggle" },
  { "SUPER + SHIFT + B", "Toggle Top Bar", "~/bin/toggle-waybar" },
  { "SUPER + SHIFT + C", "Color Center", "~/bin/toggle-chromack --toggle" },
  { "SUPER + SHIFT + CTRL + W", "Reload Waybar", "~/bin/reload-waybar" },
  { "SUPER + D", "Toggle Dock", "~/bin/toggle-dock" },
}

for _, binding in ipairs(bindings) do
  hl.bind(binding[1], hl.dsp.exec_cmd(binding[3]), { description = binding[2] })
end
