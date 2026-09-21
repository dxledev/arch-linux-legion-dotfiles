local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local home = os.getenv("HOME")
local noctalia = os.getenv("NOCTALIA_BIN") or (config_home .. "/noctalia/.runtime/bin/noctalia")
local lock_script = home .. "/bin/system-lock"

local shell_bindings = {
  "SUPER + SHIFT + ALT + S",
  "SUPER + ALT + S",
  "SUPER + ALT + F",
  "SUPER + ALT + C",
  "SUPER + SHIFT + Z",
  "SUPER + ALT + J",
  "SUPER + SHIFT + ALT + B",
  "SUPER + ALT + I",
  "SUPER + ALT + E",
  "SUPER + ALT + U",
  "SUPER + ALT + L",
  "SUPER + ALT + SHIFT + SPACE",
  "SUPER + ALT + SHIFT + C",
  "SUPER + SHIFT + ALT + T",
  "SUPER + SPACE",
  "SUPER + ALT + SPACE",
  "SUPER + ALT + T",
  "SUPER + CTRL + ALT + SPACE",
  "SUPER + SHIFT + ALT + P",
  "SUPER + ALT + P",
  "SUPER + ALT + K",
  "SUPER + SHIFT + ALT + K",
  "SUPER + SHIFT + ALT + L",
  "SUPER + SHIFT + D",
  "SUPER + SHIFT + N",
  "SUPER + D",
  "SUPER + SHIFT + B",
  "SUPER + SHIFT + C",
  "SUPER + SHIFT + ALT + W",
  "SUPER + ALT + B",
  "SUPER + ALT + D",
  "SUPER + SHIFT + CTRL + W",
  "SUPER + SHIFT + L",
  "XF86AudioRaiseVolume",
  "XF86AudioLowerVolume",
  "SUPER + XF86AudioRaiseVolume",
  "SUPER + XF86AudioLowerVolume",
  "XF86AudioMute",
  "SUPER + SHIFT + F1",
  "SUPER + F1",
  "SUPER + F2",
  "SUPER + SHIFT + F3",
  "SUPER + F3",
  "SUPER + F4",
}

for _, key in ipairs(shell_bindings) do
  hl.unbind(key)
end

local function command(name)
  return noctalia .. " msg " .. name
end

local function bind_panel(key, description, panel)
  hl.unbind(key)
  hl.bind(key, hl.dsp.exec_cmd(command("panel-toggle " .. panel)), { description = description })
end

local function bind_message(key, description, message, options)
  hl.unbind(key)
  hl.bind(key, hl.dsp.exec_cmd(command(message)), options or { description = description })
end

bind_panel("SUPER + SPACE", "App Launcher", "launcher")
bind_panel("SUPER + SHIFT + D", "Dashboard", "control-center")
bind_panel("SUPER + ALT + A", "Audio Menu", "control-center audio")
bind_panel("SUPER + ALT + C", "Clipboard Menu", "clipboard")
bind_panel("SUPER + CTRL + ALT + SPACE", "Wallpaper Panel", "wallpaper")
bind_message("SUPER + ALT + T", "Theme Settings", "settings-toggle theme")
bind_panel("SUPER + ALT + P", "Session", "session")
bind_panel("SUPER + SHIFT + B", "Session", "session")

hl.unbind("SUPER + SHIFT + L")
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd(lock_script .. " --wait"), { description = "Lock Screen" })

local volume_bindings = {
  { "XF86AudioRaiseVolume", "Volume Up", "volume-up 1%" },
  { "XF86AudioLowerVolume", "Volume Down", "volume-down 1%" },
  { "SUPER + XF86AudioRaiseVolume", "Volume Up", "volume-up 5%" },
  { "SUPER + XF86AudioLowerVolume", "Volume Down", "volume-down 5%" },
  { "XF86AudioMute", "Mute", "volume-mute" },
}

for _, binding in ipairs(volume_bindings) do
  bind_message(binding[1], binding[2], binding[3], { description = binding[2], locked = true })
end

local brightness_bindings = {
  { "SUPER + SHIFT + F1", "Minimum Laptop Brightness", "brightness-set DP-1 0" },
  { "SUPER + F1", "Decrease Laptop Brightness", "brightness-down DP-1 5%" },
  { "SUPER + F2", "Increase Laptop Brightness", "brightness-up DP-1 5%" },
  { "SUPER + SHIFT + F3", "Minimum HDMI Brightness", "brightness-set HDMI-A-1 0" },
  { "SUPER + F3", "Decrease HDMI Brightness", "brightness-down HDMI-A-1 5%" },
  { "SUPER + F4", "Increase HDMI Brightness", "brightness-up HDMI-A-1 5%" },
}

for _, binding in ipairs(brightness_bindings) do
  bind_message(binding[1], binding[2], binding[3])
end
