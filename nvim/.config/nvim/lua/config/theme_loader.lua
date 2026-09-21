local M = {}

local config_home = vim.env.XDG_CONFIG_HOME
if not config_home or config_home == "" then
  config_home = vim.fn.expand("~/.config")
end

M.theme_file = config_home .. "/themes/.caelestia-use/neovim.lua"
M.fallback_theme_file = vim.fn.stdpath("config") .. "/lua/config/current_theme.lua"
local applied = false

function M.selected_theme_file()
  local stat = (vim.uv or vim.loop).fs_stat(M.theme_file)
  if stat then
    return M.theme_file
  end

  return M.fallback_theme_file
end

function M.apply(silent)
  local theme_file = M.selected_theme_file()
  local ok, err = pcall(dofile, theme_file)
  applied = ok

  if not ok and not silent then
    vim.notify("Theme reload failed: " .. err, vim.log.levels.ERROR)
  end

  return ok
end

function M.was_applied()
  return applied
end

return M
