-- require("island-mode-keybindings")
-- require("waybar-mode-keybindings")
require("noctalia-mode-keybindings")

require("autostart")
require("keybindings")
require("monitors")
require("decorations")
require("borders")
require("animations")
require("environment")
require("cursor")
require("windows")
require("permissions")
require("inputs")
require("plugins")
require("workspaces")
require("hypridle")
require("hyprlock")
require("hyprsunset")
require("hymission")
require("hymission-background")
require("xdph")

require("custom-layouts.grid")
require("custom-layouts.spiral")
require("custom-layouts.manual")
require("custom-layouts.niriscroll")
require("custom-layouts.centerstack")

hl.bind("SUPER + CTRL + SHIFT + O", hl.dsp.exec_cmd("~/bin/launch-terminal"))

local shell_bindings = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/quickshell/active/integration/hyprland.lua"
local shell_config = io.open(shell_bindings, "r")
if shell_config then
  shell_config:close()
  dofile(shell_bindings)
end

do local path = (os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")) .. "/quickshell/shared/display/monitor-rules.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end

-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.
do local path = os.getenv("HOME") .. "/.config/hypr/hyprmoncfg-monitors.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end
