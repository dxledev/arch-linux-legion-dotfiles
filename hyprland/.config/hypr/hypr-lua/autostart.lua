local startup_commands = {
  "hyprpm reload -nn && hyprctl dismissnotify",
  "waybar",
  "swayosd-server",
  "awww-daemon",
  "hyprlock",
  "~/bin/launch-dashboard",
  "~/bin/launch-ward",
  "~/bin/launch-wardnc",
  "~/bin/launch-chromack",
  "~/bin/launch-hypridle",
  "~/bin/launch-hyprsunset",
  "~/bin/launch-cliphist",
  "~/bin/reload-dashboard",
  "~/bin/launch-obs-log-notify",
  "~/bin/watch-discordspace",
  "eval $(gnome-keyring-daemon --start --components=secrets)",
  "dbus-update-activation-environment --all",
  "rm -rf /tmp/hypr*",
}

hl.on("hyprland.start", function()
  for _, command in ipairs(startup_commands) do
    hl.exec_cmd(command)
  end
end)
