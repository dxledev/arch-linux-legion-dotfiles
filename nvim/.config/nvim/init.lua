-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
require("config.theme_watcher")

vim.cmd([[
  highlight Normal guibg=NONE
  highlight NormalNC guibg=NONE
  highlight EndOfBuffer guibg=NONE
  highlight SignColumn guibg=NONE
]])

vim.opt.spell = false

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    vim.opt_local.indentexpr = ""
    vim.opt_local.cindent = false
    vim.opt_local.smartindent = false
    vim.opt_local.autoindent = true

    -- cindent trigger keys
    vim.opt_local.cinkeys:remove(":")

    -- indentexpr trigger keys
    vim.opt_local.indentkeys:remove(":")
  end,
})
