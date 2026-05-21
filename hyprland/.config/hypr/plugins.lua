local hyprctl_bin = "/usr/bin/hyprctl"
local hyprpm_bin = "/usr/bin/hyprpm"
local grep_bin = "/usr/bin/grep"
local startup_reload_delay = 1

local fallback_plugins = {
  { name = "dynamic-cursors", path = "/var/cache/hyprpm/dxle/dynamic-cursors/dynamic-cursors.so" },
  { name = "hymission", path = "/var/cache/hyprpm/dxle/hymission/hymission.so" },
  { name = "Hyprspace", path = "/home/dxle/.config/hypr/.plugins/Hyprspace/Hyprspace.so" },
}

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

local function file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end

  return false
end

local function dynamic_cursors_config_command()
  return hyprctl_bin .. " eval " .. shell_quote(dynamic_cursors_config_eval)
end

local function plugin_fallback_command(plugin)
  if not file_exists(plugin.path) then
    return nil
  end

  return hyprctl_bin
    .. " plugin list | "
    .. grep_bin
    .. " -Fq "
    .. shell_quote(plugin.name)
    .. " || "
    .. hyprctl_bin
    .. " plugin load "
    .. shell_quote(plugin.path)
    .. " || true"
end

local function plugin_reload_commands()
  local commands = {
    hyprpm_bin .. " reload || true",
    dynamic_cursors_config_command(),
  }

  for _, plugin in ipairs(fallback_plugins) do
    local fallback = plugin_fallback_command(plugin)
    if fallback then
      table.insert(commands, 2, fallback)
    end
  end

  return commands
end

local function apply_plugins()
  hl.exec_cmd(table.concat(plugin_reload_commands(), " ; "))
end

hl.on("hyprland.start", function()
  local commands = plugin_reload_commands()

  table.insert(commands, hyprctl_bin .. " dismissnotify")
  hl.exec_cmd("sleep " .. startup_reload_delay .. " ; " .. table.concat(commands, " ; "))
end)

hl.on("config.reloaded", apply_plugins)
