local startup_commands = {
  "if [ \"$(~/bin/toggle-shell-mode --status)\" = quickshell ]; then CAELESTIA_START_LOCKED=1 ~/bin/toggle-shell-mode --apply; else ~/bin/system-lock --wait & lock_pid=$!; ~/bin/toggle-shell-mode --apply; wait \"$lock_pid\"; fi",
  "hyprpm reload && hyprctl reload",
  "~/bin/bg-refresh-current --wait-for-lock",
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
