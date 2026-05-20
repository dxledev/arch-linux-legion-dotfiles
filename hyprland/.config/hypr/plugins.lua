local enable_hyprspace = false

local dynamic_cursors_plugin = "/var/cache/hyprpm/dxle/dynamic-cursors/dynamic-cursors.so"
local hyprspace_plugin = "/home/dxle/.config/hypr/.plugins/Hyprspace/Hyprspace.so"

local dynamic_cursors_keywords = {
  "plugin:dynamic-cursors:enabled true",
  "plugin:dynamic-cursors:mode none",
  "plugin:dynamic-cursors:threshold 2",
  "plugin:dynamic-cursors:rotate:length 20",
  "plugin:dynamic-cursors:rotate:offset 0.0",
  "plugin:dynamic-cursors:tilt:limit 5000",
  "plugin:dynamic-cursors:tilt:function negative_quadratic",
  "plugin:dynamic-cursors:tilt:window 100",
  "plugin:dynamic-cursors:tilt:full_tilt 60",
  "plugin:dynamic-cursors:stretch:limit 3000",
  "plugin:dynamic-cursors:stretch:function quadratic",
  "plugin:dynamic-cursors:stretch:window 100",
  "plugin:dynamic-cursors:shake:enabled true",
  "plugin:dynamic-cursors:shake:nearest false",
  "plugin:dynamic-cursors:shake:threshold 8.0",
  "plugin:dynamic-cursors:shake:base 2.0",
  "plugin:dynamic-cursors:shake:speed 2.0",
  "plugin:dynamic-cursors:shake:influence 0.0",
  "plugin:dynamic-cursors:shake:limit 4.0",
  "plugin:dynamic-cursors:shake:timeout 1500",
  "plugin:dynamic-cursors:shake:effects false",
  "plugin:dynamic-cursors:shake:ipc false",
  "plugin:dynamic-cursors:hyprcursor:nearest false",
  "plugin:dynamic-cursors:hyprcursor:enabled false",
  "plugin:dynamic-cursors:hyprcursor:resolution -1",
  "plugin:dynamic-cursors:hyprcursor:fallback clientside",
}

local hyprspace_keywords = {
  "plugin:overview:panelColor rgba(00000000)",
  "plugin:overview:panelBorderColor rgba(00000000)",
  "plugin:overview:workspaceActiveBackground rgba(00000040)",
  "plugin:overview:workspaceInactiveBackground rgba(00000080)",
  "plugin:overview:workspaceActiveBorder rgba(ffffff40)",
  "plugin:overview:workspaceInactiveBorder rgba(ffffff00)",
  "plugin:overview:panelHeight 250",
  "plugin:overview:panelBorderWidth 2",
  "plugin:overview:workspaceMargin 12",
  "plugin:overview:workspaceBorderSize 1",
  "plugin:overview:centerAligned 1",
  "plugin:overview:drawActiveWorkspace 1",
  "plugin:overview:overrideGaps 1",
  "plugin:overview:gapsIn 20",
  "plugin:overview:gapsOut 60",
  "plugin:overview:autoDrag 1",
  "plugin:overview:autoScroll 1",
  "plugin:overview:exitOnClick 1",
  "plugin:overview:exitOnSwitch 0",
  "plugin:overview:showNewWorkspace 1",
  "plugin:overview:showEmptyWorkspace 1",
  "plugin:overview:showSpecialWorkspace 0",
  "plugin:overview:disableGestures 0",
  "plugin:overview:disableBlur 1",
  "plugin:overview:renderWindows 0",
  "plugin:overview:renderLayers 0",
  "plugin:overview:dragAlpha 0.2",
  "plugin:overview:exitKey Escape",
}

local function keyword_command(keyword)
  return "hyprctl keyword " .. keyword
end

local function active_plugin_keywords()
  local keywords = {}

  for _, keyword in ipairs(dynamic_cursors_keywords) do
    table.insert(keywords, keyword)
  end

  if enable_hyprspace then
    for _, keyword in ipairs(hyprspace_keywords) do
      table.insert(keywords, keyword)
    end
  end

  return keywords
end

local function plugin_load_commands()
  local commands = {
    "hyprctl plugin load " .. dynamic_cursors_plugin .. " || true",
  }

  if enable_hyprspace then
    table.insert(commands, "hyprctl plugin load " .. hyprspace_plugin .. " || true")
  end

  return commands
end

local function apply_plugin_keywords()
  hl.exec_cmd(table.concat(plugin_load_commands(), " ; "))

  for _, keyword in ipairs(active_plugin_keywords()) do
    hl.exec_cmd(keyword_command(keyword))
  end
end

hl.on("hyprland.start", function()
  local commands = plugin_load_commands()

  for _, keyword in ipairs(active_plugin_keywords()) do
    table.insert(commands, keyword_command(keyword))
  end

  table.insert(commands, "hyprctl dismissnotify")
  hl.exec_cmd(table.concat(commands, " ; "))
end)

hl.on("config.reloaded", apply_plugin_keywords)
