local M = {}

M.theme_file = vim.fn.stdpath("config") .. "/lua/config/current_theme.lua"
local applied = false

function M.apply(silent)
  local ok, err = pcall(dofile, M.theme_file)
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
