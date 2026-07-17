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
