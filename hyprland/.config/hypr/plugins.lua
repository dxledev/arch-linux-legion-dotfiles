local enable_hyprspace = true

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

local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
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

local function apply_plugins()
  hl.exec_cmd(table.concat(plugin_load_commands(), " ; "))
end

hl.on("hyprland.start", function()
  local commands = plugin_load_commands()

  table.insert(commands, "hyprctl dismissnotify")
  hl.exec_cmd(table.concat(commands, " ; "))
end)

hl.on("config.reloaded", apply_plugins)
