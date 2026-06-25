local mainMod = "SUPER"

local function normalize_mods(mods)
  if mods == nil or mods == "" then
    return ""
  end

  local normalized = mods:gsub("%s+", " + ")
  return normalized:gsub("^%s+", ""):gsub("%s+$", "")
end

local function keys(mods, key)
  local normalized_mods = normalize_mods(mods)
  if normalized_mods == "" then
    return key
  end

  return normalized_mods .. " + " .. key
end

local function dispatch_command(dispatcher, arg)
  if dispatcher == "exec" then
    return hl.dsp.exec_cmd(arg)
  elseif dispatcher == "movefocus" then
    return hl.dsp.focus({ direction = arg })
  elseif dispatcher == "movewindow" then
    return hl.dsp.window.move({ direction = arg })
  elseif dispatcher == "swapwindow" then
    return hl.dsp.window.swap({ direction = arg })
  elseif dispatcher == "resizeactive" then
    local x, y = arg:match("^%s*([%-0-9]+)%s+([%-0-9]+)%s*$")
    return hl.dsp.window.resize({ x = tonumber(x), y = tonumber(y), relative = true })
  elseif dispatcher == "setprop" then
    local window, prop, value = arg:match("^(%S+)%s+(%S+)%s+(.+)$")
    if window == "active" then
      return hl.dsp.window.set_prop({ prop = prop, value = value })
    end
    prop, value = arg:match("^(%S+)%s+(.+)$")
    return hl.dsp.window.set_prop({ prop = prop, value = value })
  elseif dispatcher == "fullscreen" then
    return hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })
  elseif dispatcher == "settiled" then
    return hl.dsp.window.float({ action = "unset" })
  elseif dispatcher == "centerwindow" then
    return hl.dsp.window.center()
  elseif dispatcher == "workspace" then
    return hl.plugin.hymission.workspace(arg)
  elseif dispatcher == "movetoworkspace" then
    return hl.dsp.window.move({ workspace = arg, follow = true })
  elseif dispatcher == "movetoworkspacesilent" then
    return hl.dsp.window.move({ workspace = arg, follow = false })
  elseif dispatcher == "togglespecialworkspace" then
    return hl.dsp.workspace.toggle_special(arg)
  elseif dispatcher == "killactive" then
    return hl.dsp.window.close()
  elseif dispatcher == "swapactiveworkspaces" then
    local monitor1, monitor2 = arg:match("^(%S+)%s+(%S+)$")
    return hl.dsp.workspace.swap_monitors({ monitor1 = monitor1, monitor2 = monitor2 })
  elseif dispatcher == "layoutmsg" then
    return hl.dsp.layout(arg)
  elseif dispatcher == "hymission:toggle" then
    return hl.plugin.hymission.toggle(arg ~= "" and arg or nil)
  elseif dispatcher == "hymission:open" then
    return hl.plugin.hymission.open(arg ~= "" and arg or nil)
  elseif dispatcher == "hymission:close" then
    return hl.plugin.hymission.close()
  elseif dispatcher == "hymission:debug_current_layout" then
    return hl.plugin.hymission.debug_current_layout()
  elseif dispatcher == "sendshortcut" then
    local mods, key, window = arg:match("^%s*([^,]+),%s*([^,]+),%s*(.+)%s*$")
    return hl.dsp.send_shortcut({ mods = normalize_mods(mods), key = key, window = window })
  end

  return hl.dsp.exec_cmd("hyprctl dispatch " .. dispatcher .. (arg and arg ~= "" and (" " .. arg) or ""))
end

local function bind(kind, mods, key, description, dispatcher, arg)
  local flags = {}
  if description and description ~= "" then
    flags.description = description
  end
  if kind:find("e", 1, true) then
    flags.repeating = true
  end
  if kind:find("l", 1, true) then
    flags.locked = true
  end
  if kind:find("r", 1, true) then
    flags.release = true
  end
  if kind:find("m", 1, true) then
    flags.mouse = true
  end

  hl.bind(keys(mods, key), dispatch_command(dispatcher, arg or ""), flags)
end

local function bind_exec(mods, key, description, command)
  bind("bindd", mods, key, description, "exec", command)
end

local simple_binds = {
  { mainMod, "SPACE", "App Launcher", "~/bin/menu-apps" },
  { mainMod .. " ALT", "K", "Keybindings Menu", "~/bin/menu-keybindings" },
  { mainMod .. " SHIFT ALT", "K", "Neovim Keybindings", "~/bin/menu-neovim-bindings" },
  { mainMod .. " ALT", "SPACE", "Menu", "~/bin/menu" },
  { mainMod .. " ALT", "P", "System Menu", "~/bin/menu-system" },
  { mainMod .. " ALT", "F", "File Menu", "~/bin/menu-files" },
  { mainMod .. " ALT", "L", "Layout Menu", "~/bin/menu-layout" },
  { mainMod .. " SHIFT ALT", "W", "Waybar Style Menu", "~/bin/menu-waybar" },
  { mainMod .. " SHIFT ALT", "L", "Learn Menu", "~/bin/menu-learn" },
  { mainMod .. " ALT", "C", "Clipboard Menu", "~/bin/menu-clipboard" },
  { mainMod .. " ALT SHIFT", "C", "Color Converter", "~/bin/menu-color-converter" },
  { mainMod .. " SHIFT CTRL", "C", "Config", "~/bin/menu-config" },
  { mainMod .. " ALT", "T", "Theme Menu", "~/bin/menu-theme" },
  { mainMod .. " SHIFT ALT", "T", "Style Menu", "~/bin/menu-style" },
  { mainMod .. " ALT", "B", "Top Bar Menu", "~/bin/menu-waybar" },
  { mainMod .. " SHIFT ALT", "P", "Terminal Prompt Menu", "~/bin/menu-starship" },
  { mainMod .. " ALT", "S", "Screenshot Menu", "~/bin/menu-screenshot" },
  { mainMod, "S", "Quick Region Screenshot", "~/bin/launch-screenshot-clipboard" },
  { mainMod .. " SHIFT", "S", "Quick Active Monitor Screenshot", "~/bin/launch-screenshot-active-monitor-clipboard" },
  { mainMod .. " SHIFT ALT", "S", "Capture Menu", "~/bin/menu-capture" },
  { mainMod .. " ALT", "V", "Audio Menu", "~/bin/menu-audio" },
  { mainMod .. " ALT", "I", "Install Menu", "~/bin/menu-install" },
  { mainMod .. " ALT", "E", "Emoji Menu", "~/bin/menu-emojis" },
  { mainMod .. " ALT", "U", "Unicode Menu", "~/bin/menu-unicode" },
  { mainMod .. " ALT", "N", "Share Menu", "~/bin/menu-share" },
  { mainMod .. " ALT", "J", "Tools Menu", "~/bin/menu-tools" },
  { mainMod .. " ALT", "D", "Dashboard Menu", "~/bin/menu-tasks" },
  { mainMod .. " SHIFT ALT", "B", "Border Menu", "~/bin/menu-border" },
  { mainMod .. " ALT", "W", "Workspace Axis Menu", "~/bin/menu-workspace-axis" },
  { "CTRL ALT", "SPACE", "Next Background", "~/bin/bg-next" },
  { "CTRL ALT SHIFT", "SPACE", "Previous Background", "~/bin/bg-prev" },
  { mainMod .. " CTRL ALT", "SPACE", "Set Background", "~/bin/bg-set" },
  { mainMod .. " ALT SHIFT", "SPACE", "Live Background", "~/bin/bg-live" },
  { mainMod .. " CTRL", "Space", "Toggle Background Slideshow", "~/bin/bg-toggle-slideshow" },
  { mainMod, "RETURN", "Terminal", "~/bin/launch-terminal" },
  { mainMod .. " SHIFT", "RETURN", "Main Tmux", "~/bin/launch-tmux-main" },
  { mainMod .. " CTRL ALT", "C", "Color Picker", "~/bin/launch-colorpicker" },
  { mainMod .. " SHIFT", "A", "Activity", "~/bin/launch-terminal btop" },
  { mainMod .. " SHIFT", "D", "Dashboard", "~/bin/toggle-dashboard" },
  { mainMod .. " SHIFT", "N", "Notification Center", "~/bin/toggle-wardnc --toggle" },
  { mainMod .. " SHIFT", "B", "Toggle Top Bar", "~/bin/toggle-waybar" },
  { mainMod .. " SHIFT", "C", "Color Center", "~/bin/toggle-chromack --toggle" },
  { mainMod .. " SHIFT ALT", "F", "Launch File Explorer", "nemo" },
  { mainMod, "B", "Launch Browser", "brave" },
  { mainMod .. " SHIFT CTRL ALT", "B", "Launch Alt Browser", "chromium" },
  { mainMod .. " SHIFT ALT", "V", "Launch VPN Service", "~/bin/launch-vpn" },
}

for _, item in ipairs(simple_binds) do
  bind_exec(item[1], item[2], item[3], item[4])
end

bind("bindd", "ALT", "F9", "Start OBS Recording", "sendshortcut", "ALT, F9, class:^com\\.obsproject\\.Studio$")
bind("bindd", "ALT SHIFT", "F9", "Stop OBS Recording", "sendshortcut", "ALT SHIFT, F9, class:^com\\.obsproject\\.Studio$")
bind("bindd", "ALT", "F10", "Pause OBS Recording", "sendshortcut", "ALT, F10, class:^com\\.obsproject\\.Studio$")
bind("bindd", "ALT SHIFT", "F10", "Resume OBS Recording", "sendshortcut", "ALT SHIFT, F10, class:^com\\.obsproject\\.Studio$")

-- for _, direction in ipairs({ { "Left", "l" }, { "Right", "r" }, { "Up", "u" }, { "Down", "d" } }) do
--   bind("bindd", mainMod, direction[1], "Focus Window " .. direction[1], "movefocus", direction[2])
--   bind("bindd", mainMod .. " SHIFT", direction[1], "Move Window " .. direction[1], "movewindow", direction[2])
--   bind("bindd", mainMod .. " SHIFT CTRL", direction[1], "Swap Window " .. direction[1], "swapwindow", direction[2])
-- end

local function is_scrolling_workspace()
  local ws = hl.get_active_workspace()
  return ws ~= nil and ws.tiled_layout == "scrolling"
end

local function dynamic_movefocus(dir)
  if is_scrolling_workspace() then
    if dir == "l" then
      hl.dispatch(hl.dsp.layout("move -col"))
    elseif dir == "r" then
      hl.dispatch(hl.dsp.layout("move +col"))
    else
      hl.dispatch(hl.dsp.focus({ direction = dir }))
    end

    return
  end

  hl.dispatch(hl.dsp.focus({ direction = dir }))
end

for _, direction in ipairs({ { "Left", "l" }, { "Right", "r" }, { "Up", "u" }, { "Down", "d" } }) do
  hl.bind(
    keys(mainMod, direction[1]),
    function()
      dynamic_movefocus(direction[2])
    end,
    { description = "Focus Window " .. direction[1] }
  )

  bind("bindd", mainMod .. " SHIFT", direction[1], "Move Window " .. direction[1], "movewindow", direction[2])
  bind("bindd", mainMod .. " SHIFT CTRL", direction[1], "Swap Window " .. direction[1], "swapwindow", direction[2])
end


hl.config({ binds = { drag_threshold = 10 } })
hl.bind(keys(mainMod, "mouse:272"), hl.dsp.window.drag(), { mouse = true })
hl.bind(keys(mainMod, "mouse:273"), hl.dsp.window.resize(), { mouse = true })

bind("bindde", "CTRL", "Right", "Resize Window Right", "resizeactive", "25 0")
bind("bindde", "CTRL", "Left", "Resize Window Left", "resizeactive", "-25 0")
bind("bindde", "CTRL", "Up", "Resize Window Up", "resizeactive", "0 -25")
bind("bindde", "CTRL", "Down", "Resize Window Down", "resizeactive", "0 25")

bind("bindd", mainMod, "O", "Toggle Window Opacity", "setprop", "active opaque toggle")
hl.bind(keys(mainMod, "F"), function()
  hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  hl.dispatch(hl.dsp.window.resize({ x = 1200, y = 800, relative = false }))
  hl.dispatch(hl.dsp.window.center())
end, { description = "Toggle Window Floating Status" })
bind("bindd", mainMod .. " SHIFT", "F", "Toggle Fullscreen", "fullscreen", "")
bind("bindd", mainMod, "T", "Toggle Window Tiling Status", "settiled", "")
bind("bindd", mainMod, "P", "Pin Window", "hyprctl dispatch setfloating && hyprctl dispatch resizeactive exact 725 510 && hyprctl dispatch pin")
hl.bind(keys(mainMod, "P"), function()
  hl.dispatch(hl.dsp.window.float({ action = "on" }))
  hl.dispatch(hl.dsp.window.resize({ x = 725, y = 510, relative = false }))
  hl.dispatch(hl.dsp.window.pin({ action = "on" }))
end, { descrption = "Pin Window" })
bind("bindd", mainMod, "C", "Center Floating Window", "centerwindow", "")

bind("bindl", "", "XF86AudioRaiseVolume", "", "exec", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume +1")
bind("bindl", "", "XF86AudioLowerVolume", "", "exec", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume -1")
bind("bindl", mainMod, "XF86AudioRaiseVolume", "", "exec", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume +5")
bind("bindl", mainMod, "XF86AudioLowerVolume", "", "exec", "~/bin/system-volume --description \"Acer Technologies KG271U\" --output-volume -5")
bind("bindl", "", "XF86AudioMute", "", "exec", "~/bin/knob-press")
bind("bindrl", "", "XF86AudioMute", "", "exec", "~/bin/knob-release")

local media_binds = {
  { "", "F11", "Previous Spotify Track", "~/bin/media-controls/spotify-play-previous" },
  { "", "F12", "Next Spotify Track", "~/bin/media-controls/spotify-play-next" },
  { "", "Delete", "Play/Pause Spotify Track", "~/bin/media-controls/spotify-play-pause" },
  { mainMod, "Delete", "Replay Spotify Track", "~/bin/media-controls/spotify-restart-track" },
  { mainMod .. " SHIFT", "Delete", "Show Current Spotify Track", "~/bin/media-controls/spotify-current-song" },
  { mainMod, "F11", "Rewind Spotify Track", "~/bin/media-controls/spotify-rewind" },
  { mainMod, "F12", "Forward Spotify Track", "~/bin/media-controls/spotify-forward" },
}

for _, item in ipairs(media_binds) do
  bind("binddl", item[1], item[2], item[3], "exec", item[4])
end

bind_exec("", "F9", "Play/Pause Focused YouTube Video", "~/bin/media-controls/youtube-play-pause")
bind_exec(mainMod, "F9", "Play/Pause Focused Netflix Video", "~/bin/media-controls/netflix-play-pause")

for workspace = 1, 10 do
  local key = tostring(workspace % 10)
  local label = key == "0" and "0 (Monitor 2)" or key
  bind("bindd", mainMod, key, "Focus Workspace " .. label, "workspace", tostring(workspace))
  bind("bindd", mainMod .. " SHIFT", key, "Move To Workspace " .. label, "movetoworkspace", tostring(workspace))
  bind("bindd", mainMod .. " ALT SHIFT", key, "Silently Move To Workspace " .. label, "movetoworkspacesilent", tostring(workspace))
end

bind("bindd", mainMod, "F5", "Focus Workspace 11", "workspace", "11")
bind("bindd", mainMod .. " SHIFT", "F5", "Move To Workspace 11", "movetoworkspace", "11")
bind("bindd", mainMod .. " ALT SHIFT", "F5", "Silently Move To Workspace 11", "movetoworkspacesilent", "11")

bind_exec(mainMod .. " ALT", "equal", "Move Window To Empty Workspace", "~/bin/hypr-move-to-empty-workspace")

bind("bind", mainMod, "KP_Next", "", "exec", "~/bin/hypr-focus-special-workspace scratchpad")
bind("bind", mainMod .. " SHIFT", "KP_Next", "", "exec", "hyprctl dispatch setfloating && hyprctl dispatch resizeactive exact 1200 800 && hyprctl dispatch centerwindow && hyprctl dispatch movetoworkspace special:scratchpad")
bind("bind", mainMod .. " SHIFT ALT", "KP_Next", "", "exec", "~/bin/launch-obsidian")
bind("bind", mainMod, "KP_Down", "", "exec", "~/bin/hypr-focus-special-workspace mediaspace")
bind("bind", mainMod .. " SHIFT ALT", "KP_Down", "", "exec", "~/bin/launch-spotify")
bind("bind", mainMod, "KP_End", "", "exec", "~/bin/hypr-focus-special-workspace discordspace")
bind("bind", mainMod .. " SHIFT ALT", "KP_End", "", "exec", "~/bin/launch-discord")
bind("bind", mainMod, "KP_Left", "", "exec", "~/bin/hypr-focus-special-workspace socialspace")
bind("bind", mainMod .. " SHIFT ALT", "KP_Left", "", "exec", "~/bin/launch-instagram")
bind("bind", mainMod .. " CTRL ALT", "KP_Left", "", "exec", "~/bin/launch-tiktok")
bind("bind", mainMod .. " SHIFT CTRL", "EQUAL", "", "togglespecialworkspace", "floating")

local environment_binds = {
  { mainMod .. " SHIFT CTRL", "R", "Reload Hyprland", "~/bin/reload-hyprland" },
  { mainMod .. " SHIFT CTRL", "W", "Reload Waybar", "~/bin/reload-waybar" },
  { mainMod, "D", "Toggle Dock", "~/bin/toggle-dock" },
  { mainMod .. " SHIFT", "P", "Display Manager", "~/bin/launch-window-floating 1200 800 nwg-displays" },
  { mainMod .. " SHIFT", "L", "Lock Screen", "$HOME/.config/hyprlock/scripts/launch-lock-screen.sh" },
  { mainMod .. " SHIFT", "Z", "Toggle Zen Mode", "~/bin/toggle-zen-mode" },
  { mainMod, "I", "Toggle Idle Lock", "~/bin/system-toggle-idle-lock" },
  { mainMod .. " CTRL", "S", "Toggle Sleep", "~/bin/system-toggle-sleep" },
}

for _, item in ipairs(environment_binds) do
  bind_exec(item[1], item[2], item[3], item[4])
end

bind("bindd", mainMod, "Q", "Kill Active Window", "killactive", "")
bind("bindd", mainMod .. " SHIFT", "Q", "Kill Active Window", "killactive", "")
bind("bindd", mainMod .. " SHIFT CTRL", "F12", "Swap Active Workspaces Between Monitors", "swapactiveworkspaces", "DP-1 HDMI-A-1")
bind("binddl", mainMod, "L", "Toggle Nightlight", "exec", "~/bin/system-toggle-nightlight")
-- bind_exec(mainMod, "TAB", "Toggle Workspace Overview", "~/bin/hypr-toggle-overview")
bind("binddl", mainMod, "TAB", "Toggle Workspace Control", "hymission:toggle", "onlycurrentworkspace")
bind("binddl", mainMod .. " SHIFT", "TAB", "Toggle Mission Control", "hymission:toggle", "forceall")
bind("bind", mainMod .. " SHIFT", "mouse_down", "", "workspace", "+1")
bind("bind", mainMod .. " SHIFT", "mouse_up", "", "workspace", "-1")
bind("bind", mainMod, "mouse_down", "", "movefocus", "right")
bind("bind", mainMod, "mouse_up", "", "movefocus", "left")

bind("bindd", mainMod .. " ALT", "Right", "Focus Window Right (Scrolling)", "layoutmsg", "move +col")
bind("bindd", mainMod .. " ALT", "Left", "Focus Window Left (Scrolling)", "layoutmsg", "move -col")
bind("bindd", "SHIFT CTRL", "Right", "Next Window Size (Scrolling)", "layoutmsg", "colresize +conf")
bind("bindd", "SHIFT CTRL", "Left", "Prev Window Size (Scrolling)", "layoutmsg", "colresize -conf")
bind("bindd", mainMod, "W", "Full Size Window (Scrolling)", "layoutmsg", "colresize 1.0")
bind("bindd", "SHIFT ALT", "W", "Half Size Window (Scrolling)", "layoutmsg", "colresize 0.5")
bind("bindd", mainMod .. " SHIFT CTRL ALT", "W", "Half Size Window (Scrolling)", "layoutmsg", "colresize 0.5")
bind("bindd", mainMod .. " SHIFT", "W", "Un-Full-Size Window (Scrolling)", "layoutmsg", "colresize 0.95")
bind("bindd", mainMod .. " SHIFT CTRL ALT", "Left", "Swap Window Left (Scrolling)", "layoutmsg", "swapcol l")
bind("bindd", mainMod .. " SHIFT CTRL ALT", "Right", "Swap Window Right (Scrolling)", "layoutmsg", "swapcol r")
bind("bindd", mainMod .. " SHIFT CTRL ALT", "P", "Promote Column (Scrolling)", "layoutmsg", "promote")
bind("bindd", "ALT", "H", "Swap Window Left (Scrolling)", "layoutmsg", "swapcol l")
bind("bindd", "ALT", "L", "Swap Window Right (Scrolling)", "layoutmsg", "swapcol r")
bind_exec("ALT", "S", "Toggle Focus Method (Scrolling)", "~/bin/hypr-toggle-scrolling-focus")

bind("bind", mainMod .. " CTRL", "mouse_down", "", "layoutmsg", "cyclenext")
bind("bind", mainMod .. " CTRL", "mouse_up", "", "layoutmsg", "cycleprev")
bind("bindd", mainMod .. " CTRL", "right", "Next Window (Monocle)", "layoutmsg", "cyclenext")
bind("bindd", mainMod .. " CTRL", "left", "Prev Window (Monocle)", "layoutmsg", "cycleprev")

hl.bind(mainMod .. " + CTRL + K", hl.dsp.exec_cmd("hyprctl kill"), { release = true, description = "Kill Mode" })

local zoom_in = "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '.float * 1.1')"
local zoom_out = "hyprctl -q keyword cursor:zoom_factor $(hyprctl getoption cursor:zoom_factor -j | jq '(.float * 0.9) | if . < 1 then 1 else . end')"
bind("bind", "CTRL ALT", "mouse_down", "", "exec", zoom_in)
bind("bind", "CTRL ALT", "mouse_up", "", "exec", zoom_out)
bind("binded", "CTRL ALT", "EQUAL", "Zoom In", "exec", zoom_in)
bind("binded", "CTRL ALT", "MINUS", "Zoom Out", "exec", zoom_out)
bind_exec("ALT SHIFT", "MINUS", "Reset Zoom", "hyprctl -q keyword cursor:zoom_factor 1")
bind("bind", "ALT SHIFT", "mouse_up", "", "exec", "hyprctl -q keyword cursor:zoom_factor 1")
bind("bind", "ALT SHIFT", "mouse_down", "", "exec", "hyprctl -q keyword cursor:zoom_factor 1")

local brightness_binds = {
  { mainMod .. " SHIFT", "F1", "Minimize ASUS Brightness", "~/bin/system-brightness-dp min" },
  { mainMod, "F1", "Decrease ASUS Brightness", "~/bin/system-brightness-dp down" },
  { mainMod, "F2", "Increase ASUS Brightness", "~/bin/system-brightness-dp up" },
  { mainMod .. " SHIFT", "F3", "Minimize Acer Brightness", "~/bin/system-brightness-hdmi min" },
  { mainMod, "F3", "Decrease Acer Brightness", "~/bin/system-brightness-hdmi down" },
  { mainMod, "F4", "Increase Acer Brightness", "~/bin/system-brightness-hdmi up" },
}

for _, item in ipairs(brightness_binds) do
  bind_exec(item[1], item[2], item[3], item[4])
end
