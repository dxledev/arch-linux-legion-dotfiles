local enable_hyprspace = false

local dynamic_cursors_plugin = "/var/cache/hyprpm/dxle/dynamic-cursors/dynamic-cursors.so"
local hyprspace_plugin = "/home/dxle/.config/hypr/.plugins/Hyprspace/Hyprspace.so"

local dynamic_cursors_config_eval = [[
hl.config({
  plugin = {
    dynamic_cursors = {
      enabled = true,
      mode = "none",
      threshold = 2,
      rotate = {
        length = 20,
        offset = 0.0,
      },
      stretch = {
        limit = 3000,
        activation = "quadratic",
        window = 100,
      },
      shake = {
        enabled = true,
        threshold = 6.0,
        base = 4.0,
        speed = 3.0,
        influence = 0.0,
        limit = 4.0,
        timeout = 1500,
        effects = false,
        ipc = false,
      },
      hyprcursor = {
        nearest = false,
        enabled = false,
        resolution = -1,
        fallback = "left_ptr",
      },
    },
  },
})
]]

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

local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

local function active_plugin_keywords()
  local keywords = {}

  if enable_hyprspace then
    for _, keyword in ipairs(hyprspace_keywords) do
      table.insert(keywords, keyword)
    end
  end

  return keywords
end

local function dynamic_cursors_config_command()
  return "hyprctl eval " .. shell_quote(dynamic_cursors_config_eval)
end

local function plugin_load_commands()
  local commands = {
    "hyprctl plugin load " .. dynamic_cursors_plugin .. " || true",
    dynamic_cursors_config_command(),
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
