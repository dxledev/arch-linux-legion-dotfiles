-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
local function load_border_yaml_color()
  local path = vim.fn.expand("/mnt/c/Users/daled/.config/tacky-borders/config.yaml")
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then return "#ffffff" end

  local in_active = false

  for _, line in ipairs(lines) do
    if line:match("^%s*active_color:%s*$") then
      in_active = true
    elseif in_active then
      local color = line:match("#%x%x%x%x%x%x")
      if color then
        return color
      end
      -- stop if we leave the block
      if line:match("^%S") then
        in_active = false
      end
    end
  end

  return "#ffffff"
end

local function grayify(hex, factor)
  -- factor: 0 = original color, 1 = full gray
  factor = factor or 0.55

  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)

  local gray = math.floor((r + g + b) / 3)

  r = math.floor(r * (1 - factor) + gray * factor)
  g = math.floor(g * (1 - factor) + gray * factor)
  b = math.floor(b * (1 - factor) + gray * factor)

  return string.format("#%02x%02x%02x", r, g, b)
end

local border_color = load_border_yaml_color()
local muted_border = grayify(border_color, 0.6) -- adjust 0.5–0.7 if needed

vim.api.nvim_set_hl(0, "FloatBorder", {
  fg = muted_border,
  bg = "NONE",
})

vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
vim.api.nvim_set_hl(0, "FloatTitle", { bg = "NONE" })
vim.api.nvim_set_hl(0, "FloatShadow", { bg = "NONE" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end
})

vim.opt.spell = false

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text", "markdown" },
  callback = function()
    vim.opt_local.spell = false
  end,
})

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    vim.opt_local.spell = false
  end,
})
