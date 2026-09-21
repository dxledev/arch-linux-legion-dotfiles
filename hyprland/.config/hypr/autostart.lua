local startup_commands = {
  "~/bin/toggle-shell-mode --apply",
  "~/bin/launch-hypridle",
  "~/bin/launch-hyprsunset",
  "~/bin/launch-cliphist",
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
