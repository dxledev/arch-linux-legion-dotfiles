local hyprctl_bin = "/usr/bin/hyprctl"
local hyprpm_bin = "/usr/bin/hyprpm"
local grep_bin = "/usr/bin/grep"
local flock_bin = "/usr/bin/flock"
local plugin_reload_lock = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/hyprpm-dxle-reload.lock"
local startup_reload_delay = 1

local fallback_plugins = {
  { name = "dynamic-cursors", path = "/var/cache/hyprpm/dxle/dynamic-cursors/dynamic-cursors.so" },
  { name = "hymission", path = "/var/cache/hyprpm/dxle/hymission/hymission.so" },
}

if hl.plugin.dynamic_cursors then
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
end

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
  }

  for _, plugin in ipairs(fallback_plugins) do
    local fallback = plugin_fallback_command(plugin)
    if fallback then
      table.insert(commands, 2, fallback)
    end
  end

  return commands
end

local function guarded_plugin_command(commands)
  if #commands == 0 then
    return nil
  end

  return flock_bin
    .. " -n "
    .. shell_quote(plugin_reload_lock)
    .. " -c "
    .. shell_quote(table.concat(commands, " ; "))
end

hl.on("hyprland.start", function()
  local commands = plugin_reload_commands()

  table.insert(commands, hyprctl_bin .. " dismissnotify")
  local command = guarded_plugin_command(commands)
  if command then
    hl.exec_cmd("sleep " .. startup_reload_delay .. " ; " .. command)
  end
end)
