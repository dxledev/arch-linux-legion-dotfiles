local startup_commands = {
  "hyprpm reload && hyprctl reload",
  "waybar",
  "swayosd-server",
  "awww-daemon",
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
  "hyprlock",
}

hl.on("hyprland.start", function()
  for _, command in ipairs(startup_commands) do
    hl.exec_cmd(command)
  end
end)
