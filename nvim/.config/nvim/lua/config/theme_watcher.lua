local uv = vim.uv or vim.loop
local theme_loader = require("config.theme_loader")

local theme_file = theme_loader.theme_file
local theme_dir = vim.fn.fnamemodify(theme_file, ":h")
local theme_name = vim.fn.fnamemodify(theme_file, ":t")

local last_sig

local function apply()
  theme_loader.apply(false)
end

local function signature(stat)
  if not stat then
    return nil
  end

  return table.concat({
    stat.mtime and stat.mtime.sec or 0,
    stat.mtime and stat.mtime.nsec or 0,
    stat.size or 0,
  }, ":")
end

local function check(force)
  local stat = uv.fs_stat(theme_file)
  local sig = signature(stat)
  if sig and (force or sig ~= last_sig) then
    last_sig = sig
    apply()
  end
end

local function apply_initial_theme()
  if theme_loader.was_applied() then
    last_sig = signature(uv.fs_stat(theme_file))
    return
  end

  check(true)
end

local function on_fs_event(err, filename)
  if err then
    vim.schedule(function()
      vim.notify("Theme watcher error: " .. err, vim.log.levels.WARN)
    end)
    return
  end

  if filename == nil or filename == theme_name then
    vim.schedule(function()
      check(false)
    end)
  end
end

local fs_event = uv.new_fs_event()
if fs_event then
  fs_event:start(theme_dir, {}, on_fs_event)
end

-- poll every 300ms
local timer = uv.new_timer()
timer:start(300, 300, function()
  vim.schedule(function()
    check(false)
  end)
end)

apply_initial_theme()
