local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local root = config_home .. "/quickshell"
local mode = io.open(config_home .. "/hypr/hyprland.lua", "r")
local quickshell = false
if mode then
    quickshell = mode:read("*a"):match('%-%-%s*require%("waybar%-mode%-keybindings"%)') ~= nil
    mode:close()
end

if not quickshell then return end

local ipc = root .. "/scripts/quickshell -p " .. root .. "/shell.qml ipc call "
local bindings = {
    { "SUPER + SPACE", "Caelestia Launcher", "drawers toggle launcher" },
    { "SUPER + SHIFT + D", "Caelestia Dashboard", "drawers toggle dashboard" },
    { "SUPER + SHIFT + N", "Caelestia Notifications", "drawers toggle sidebar" },
    { "SUPER + D", "Caelestia Utilities", "drawers toggle utilities" },
    { "SUPER + SHIFT + B", "Caelestia Session", "drawers toggle session" },
    { "SUPER + SHIFT + C", "Caelestia Settings", "nexus open" },
}

for _, binding in ipairs(bindings) do
    hl.unbind(binding[1])
    hl.bind(binding[1], hl.dsp.exec_cmd(ipc .. binding[3]), { description = binding[2] })
end
