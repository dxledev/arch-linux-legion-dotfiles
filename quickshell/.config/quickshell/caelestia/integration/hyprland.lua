local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local root = config_home .. "/quickshell"
local mode_script = os.getenv("SHELL_MODE_SCRIPT") or (os.getenv("HOME") .. "/bin/toggle-shell-mode")
local mode_pipe = io.popen(mode_script .. " --status 2>/dev/null", "r")
local mode = mode_pipe and mode_pipe:read("*l") or nil
if mode_pipe then mode_pipe:close() end

if mode ~= "caelestia" then return end

hl.window_rule({
    name = "caelestia-aether-workspace",
    match = { class = "^Aether$" },
    workspace = "special:aether",
    float = true,
    center = true,
    size = { 1320, 880 },
    animation = "slide bottom",
})

hl.workspace_rule({
    workspace = "special:aether",
    monitor = "HDMI-A-1",
    persistent = false,
})

hl.window_rule({
    name = "caelestia-nexus-workspace",
    match = { title = "^Nexus — .*$" },
    workspace = "special:nexus",
    float = true,
    center = true,
    animation = "slide bottom",
})

hl.workspace_rule({
    workspace = "special:nexus",
    monitor = "HDMI-A-1",
    persistent = false,
})

local ipc = root .. "/scripts/quickshell -p " .. root .. "/shell.qml ipc call "
local screenshot = root .. "/active/integration/screenshot"
local knob_hold = (os.getenv("HOME") .. "/bin/knob-press -- " .. root .. "/scripts/caelestia shell popouts openAudio")
local audio_popout_binding = "SUPER + ALT + V"
local superseded_audio_binding = "SUPER + CTRL + V"
for _, key in ipairs({ "SUPER + ALT + N", "SUPER + ALT + W" }) do
    hl.unbind(key)
end

local bindings = {
    { "SUPER + SHIFT + CTRL + C", "Config", "nexus open" },
    { "SUPER + SHIFT + ALT + S", "Capture Menu", "launcher menu capture" },
    { "SUPER + ALT + S", "Screenshot Menu", "launcher menu screenshot" },
    { "SUPER + ALT + E", "Emoji Menu", "launcher menu emojis" },
    { "SUPER + ALT + U", "Unicode Menu", "launcher menu unicode" },
    { "SUPER + ALT + L", "Layout Menu", "launcher menu layout" },
    { "SUPER + ALT + I", "Install Menu", "launcher menu install" },

    { "SUPER + SPACE", "Launcher", "drawers toggle launcher" },
    { "SUPER + ALT + SPACE", "Command Menu", "launcher commands" },
    { "SUPER + ALT + T", "Theme Menu", "launcher theme" },
    { "SUPER + CTRL + ALT + SPACE", "Wallpaper Menu", "launcher wallpaper" },
    { "CTRL + ALT + SPACE", "Next Wallpaper", "wallpaper next" },
    { "CTRL + ALT + SHIFT + SPACE", "Previous Wallpaper", "wallpaper previous" },
    { "SUPER + CTRL + SPACE", "Toggle Wallpaper Slideshow", "wallpaper toggleSlideshow" },
    { "SUPER + SHIFT + ALT + P", "Terminal Prompt Menu", "launcher terminalPrompt" },
    { "SUPER + ALT + P", "Session", "drawers toggle session" },
    { "SUPER + ALT + K", "Keybindings", "launcher learn keybindings" },
    { "SUPER + SHIFT + ALT + K", "Neovim Keybindings", "launcher learn neovim" },
    { "SUPER + SHIFT + ALT + L", "Learn Menu", "launcher learn ''" },
    { "SUPER + SHIFT + D", "Dashboard", "drawers toggle dashboard" },
    { "SUPER + D", "Utilities", "drawers toggle utilities" },
    { "SUPER + SHIFT + B", "Session", "drawers toggle session" },
    { "SUPER + SHIFT + C", "Chromack Color Panel", "chromack toggle" },
}

for _, binding in ipairs(bindings) do
    hl.unbind(binding[1])
    hl.bind(binding[1], hl.dsp.exec_cmd(ipc .. binding[3]), { description = binding[2] })
end

hl.unbind(superseded_audio_binding)
hl.unbind(audio_popout_binding)
hl.bind(audio_popout_binding, hl.dsp.exec_cmd(knob_hold), { description = "Audio Menu" })

hl.unbind("SUPER + S")
hl.bind("SUPER + S", hl.dsp.exec_cmd("~/bin/launch-screenshot-clipboard"), { description = "Quick Region Screenshot" })

local active_monitor_screenshot = "/usr/bin/bash " .. screenshot .. " active-monitor clipboard"
for _, key in ipairs({ "SUPER + SHIFT + S", "Print" }) do
    hl.unbind(key)
    hl.bind(key, hl.dsp.exec_cmd(active_monitor_screenshot), { description = "Active Monitor Screenshot" })
end

local lock_binding = "SUPER + SHIFT + L"
hl.unbind(lock_binding)
hl.bind(lock_binding, hl.dsp.global("caelestia:lock"), { description = "Lock Screen" })

local volume_bindings = {
    { "XF86AudioRaiseVolume", "/usr/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+" },
    { "XF86AudioLowerVolume", "/usr/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-" },
    { "SUPER + XF86AudioRaiseVolume", "/usr/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+" },
    { "SUPER + XF86AudioLowerVolume", "/usr/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" },
    { "XF86AudioMute", knob_hold },
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
