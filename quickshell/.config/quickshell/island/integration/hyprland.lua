local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local home = os.getenv("HOME")
local root = config_home .. "/quickshell/island"
local ipc = config_home .. "/quickshell/scripts/quickshell -p " .. root .. "/shell.qml ipc call island "

hl.window_rule({
    name = "island-display-editor",
    match = { title = "^Display — Layout Editor$" },
    float = true,
    center = true,
    size = { 1600, 900 },
})

local mode_owned_keys = {
    "SUPER + A",
    "SUPER + SHIFT + ALT + V", "SUPER + SHIFT + CTRL + C", "SUPER + SHIFT + CTRL + A",
    "SUPER + ALT + V", "SUPER + ALT + N", "SUPER + ALT + W", "CTRL + ALT + SPACE",
    "CTRL + ALT + SHIFT + SPACE", "SUPER + CTRL + SPACE", "SUPER + S", "SUPER + SHIFT + S",
    "Print", "SUPER + SHIFT + ALT + S", "SUPER + ALT + S", "SUPER + ALT + F",
    "SUPER + ALT + C", "SUPER + SHIFT + Z", "SUPER + ALT + J", "SUPER + SHIFT + ALT + B",
    "SUPER + ALT + I", "SUPER + ALT + E", "SUPER + ALT + U", "SUPER + ALT + L",
    "SUPER + ALT + SHIFT + SPACE", "SUPER + ALT + SHIFT + C", "SUPER + SHIFT + ALT + T",
    "SUPER + SPACE", "SUPER + ALT + SPACE", "SUPER + ALT + T", "SUPER + CTRL + ALT + SPACE",
    "SUPER + CTRL + ALT + Q", "SUPER + SHIFT + ALT + P", "SUPER + ALT + P", "SUPER + ALT + K",
    "SUPER + SHIFT + ALT + K", "SUPER + SHIFT + ALT + L", "SUPER + SHIFT + D", "SUPER + SHIFT + N",
    "SUPER + D", "SUPER + SHIFT + B", "SUPER + SHIFT + C", "SUPER + SHIFT + ALT + W",
    "SUPER + ALT + B", "SUPER + ALT + D", "SUPER + SHIFT + CTRL + W", "SUPER + SHIFT + L",
    "SUPER + ALT + A", "XF86AudioRaiseVolume", "XF86AudioLowerVolume", "SUPER + XF86AudioRaiseVolume",
    "SUPER + XF86AudioLowerVolume", "XF86AudioMute", "XF86MonBrightnessUp", "XF86MonBrightnessDown",
    "SUPER + SHIFT + F1", "SUPER + F1", "SUPER + F2", "SUPER + SHIFT + F3", "SUPER + F3", "SUPER + F4",
}
for _, key in ipairs(mode_owned_keys) do hl.unbind(key) end

local function bind(key, description, command, options)
    hl.unbind(key)
    hl.bind(key, hl.dsp.exec_cmd(command), options or { description = description })
end

local panels = {
    { "SUPER + A", "Island System", "openSystem" },
    { "SUPER + SPACE", "Island App Launcher", "openLauncher" },
    { "SUPER + ALT + SPACE", "Island Menu", "openNavigation" },
    { "SUPER + SHIFT + CTRL + C", "Island Settings", "openSettings" },
    { "SUPER + ALT + T", "Theme Selector", "openThemeSelector" },
    { "SUPER + CTRL + ALT + SPACE", "Wallpaper Selector", "openWallpaperSelector" },
    { "SUPER + CTRL + ALT + Q", "Shell Mode Menu", "openShellSwitcher" },
    { "SUPER + ALT + P", "Power Menu", "openPowerMenu" },
    { "SUPER + SHIFT + B", "Power Menu", "openPowerMenu" },
    { "SUPER + SHIFT + D", "Expand Island", "openExpandedHome" },
    { "SUPER + ALT + V", "Island Audio", "openAudioDevices" },
    { "SUPER + ALT + A", "Island Controls", "openControlCenter" },
    { "SUPER + SHIFT + N", "Island Notifications", "openNotifications" },
    { "CTRL + ALT + SPACE", "Next Wallpaper", "nextWallpaper" },
    { "CTRL + ALT + SHIFT + SPACE", "Previous Wallpaper", "previousWallpaper" },
}
for _, item in ipairs(panels) do bind(item[1], item[2], ipc .. item[3]) end

local desktop = {
    { "SUPER + ALT + C", "Clipboard", home .. "/bin/menu-clipboard" },
    { "SUPER + SHIFT + L", "Island Lock Screen", home .. "/bin/system-lock --wait" },
    { "SUPER + S", "Region Screenshot", home .. "/bin/launch-screenshot-clipboard" },
    { "SUPER + SHIFT + S", "Monitor Screenshot", home .. "/bin/launch-screenshot-active-monitor-clipboard" },
    { "Print", "Monitor Screenshot", home .. "/bin/launch-screenshot-active-monitor-clipboard" },
    { "SUPER + ALT + L", "Layout Menu", home .. "/bin/menu-layout" },
    { "SUPER + SHIFT + ALT + V", "Proton VPN", home .. "/bin/launch-vpn" },
    { "SUPER + SHIFT + F1", "Minimum DP Brightness", root .. "/scripts/ddc-brightness.sh dp min" },
    { "SUPER + F1", "Decrease DP Brightness", root .. "/scripts/ddc-brightness.sh dp down" },
    { "SUPER + F2", "Increase DP Brightness", root .. "/scripts/ddc-brightness.sh dp up" },
    { "SUPER + SHIFT + F3", "Minimum HDMI Brightness", root .. "/scripts/ddc-brightness.sh hdmi min" },
    { "SUPER + F3", "Decrease HDMI Brightness", root .. "/scripts/ddc-brightness.sh hdmi down" },
    { "SUPER + F4", "Increase HDMI Brightness", root .. "/scripts/ddc-brightness.sh hdmi up" },
}
for _, item in ipairs(desktop) do bind(item[1], item[2], item[3]) end

local volume = {
    { "XF86AudioRaiseVolume", "up" }, { "XF86AudioLowerVolume", "down" },
    { "SUPER + XF86AudioRaiseVolume", "up", "5" }, { "SUPER + XF86AudioLowerVolume", "down", "5" },
}
for _, item in ipairs(volume) do
    bind(item[1], "Island Volume", root .. "/scripts/volume.sh " .. item[2] .. " " .. (item[3] or "1"), { locked = true, repeating = item[2] ~= "mute" })
end
hl.unbind("XF86AudioMute")
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(home .. "/bin/knob-press -- " .. ipc .. "openAudioDevices"), { description = "Island Audio", locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd(home .. "/bin/knob-release --quickshell"), { description = "Mute", locked = true, release = true })
bind("XF86MonBrightnessUp", "Brightness Up", root .. "/scripts/brightness.sh +5%", { locked = true, repeating = true })
bind("XF86MonBrightnessDown", "Brightness Down", root .. "/scripts/brightness.sh 5%-", { locked = true, repeating = true })
