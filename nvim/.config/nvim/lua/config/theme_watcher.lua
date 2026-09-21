local uv = vim.uv or vim.loop
local theme_loader = require("config.theme_loader")

local selector_dir = vim.fn.fnamemodify(theme_loader.theme_file, ":h")

local last_sig
local last_file

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
  local theme_file = theme_loader.selected_theme_file()
  local stat = uv.fs_stat(theme_file)
  local sig = signature(stat)
  if sig and (force or theme_file ~= last_file or sig ~= last_sig) then
    last_file = theme_file
    last_sig = sig
    apply()
  end
end

local function apply_initial_theme()
  if theme_loader.was_applied() then
    last_file = theme_loader.selected_theme_file()
    last_sig = signature(uv.fs_stat(last_file))
    return
  end

  check(true)
end

local function on_fs_event(err)
  if err then
    vim.schedule(function()
      vim.notify("Theme watcher error: " .. err, vim.log.levels.WARN)
    end)
    return
  end

  vim.schedule(function()
    check(false)
  end)
end

local fs_event = uv.new_fs_event()
if fs_event then
  pcall(function()
    fs_event:start(selector_dir, {}, on_fs_event)
  end)
end

-- poll every 300ms
local timer = uv.new_timer()
timer:start(300, 300, function()
  vim.schedule(function()
    check(false)
  end)
end)

apply_initial_theme()
