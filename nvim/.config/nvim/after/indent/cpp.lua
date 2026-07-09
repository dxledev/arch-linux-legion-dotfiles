local function disable_cpp_reindent_triggers()
  vim.opt_local.indentexpr = ""
  vim.opt_local.indentkeys = ""
  vim.opt_local.cinkeys = ""
  vim.opt_local.cindent = false
  vim.opt_local.smartindent = false
  vim.opt_local.autoindent = true
end

disable_cpp_reindent_triggers()

local undo_indent = vim.b.undo_indent
local reset_indent = "setlocal indentexpr< indentkeys< cinkeys< cindent< smartindent< autoindent<"
vim.b.undo_indent = undo_indent and (undo_indent .. " | " .. reset_indent) or reset_indent
