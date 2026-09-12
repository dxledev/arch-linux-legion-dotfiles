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
    { "SUPER + SHIFT + ALT + S", "Caelestia Capture Menu", "launcher menu capture" },
    { "SUPER + ALT + S", "Caelestia Screenshot Menu", "launcher menu screenshot" },
    { "SUPER + ALT + E", "Caelestia Emoji Menu", "launcher menu emojis" },
    { "SUPER + ALT + U", "Caelestia Unicode Menu", "launcher menu unicode" },
    { "SUPER + ALT + L", "Caelestia Layout Menu", "launcher menu layout" },

    { "SUPER + SPACE", "Caelestia Launcher", "drawers toggle launcher" },
    { "SUPER + ALT + SPACE", "Caelestia Command Menu", "launcher commands" },
    { "SUPER + ALT + T", "Caelestia Theme Menu", "launcher theme" },
    { "SUPER + SHIFT + ALT + P", "Caelestia Terminal Prompt Menu", "launcher terminalPrompt" },
    { "SUPER + ALT + P", "Caelestia Session", "drawers toggle session" },
    { "SUPER + ALT + K", "Caelestia Keybindings", "launcher learn keybindings" },
    { "SUPER + SHIFT + ALT + K", "Caelestia Neovim Keybindings", "launcher learn neovim" },
    { "SUPER + SHIFT + ALT + L", "Caelestia Learn Menu", "launcher learn ''" },
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

local volume_bindings = {
    { "XF86AudioRaiseVolume", "/usr/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+" },
    { "XF86AudioLowerVolume", "/usr/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-" },
    { "SUPER + XF86AudioRaiseVolume", "/usr/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" },
    { "SUPER + XF86AudioLowerVolume", "/usr/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" },
    { "XF86AudioMute", "~/bin/knob-press" },
    { "XF86AudioMute", "~/bin/knob-release --quickshell", true },
}

for _, binding in ipairs(volume_bindings) do
    hl.bind(binding[1], hl.dsp.exec_cmd(binding[2]), { locked = true, release = binding[3] or false })
end

local brightness_bindings = {
    { "SUPER + SHIFT + F1", "Minimize ASUS Brightness", "DP-1", "0%" },
    { "SUPER + F1", "Decrease ASUS Brightness", "DP-1", "5%-" },
    { "SUPER + F2", "Increase ASUS Brightness", "DP-1", "+5%" },
    { "SUPER + SHIFT + F3", "Minimize Acer Brightness", "HDMI-A-1", "0%" },
    { "SUPER + F3", "Decrease Acer Brightness", "HDMI-A-1", "5%-" },
    { "SUPER + F4", "Increase Acer Brightness", "HDMI-A-1", "+5%" },
}

for _, binding in ipairs(brightness_bindings) do
    hl.bind(binding[1], hl.dsp.exec_cmd(ipc .. "brightness setFor " .. binding[3] .. " " .. binding[4]),
        { description = binding[2] })
end
