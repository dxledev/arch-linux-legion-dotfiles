local theme = "crimson" -- just change this per theme file

pcall(function()
  require("lazy").load({ plugins = { "aether" } })
end)

vim.cmd.colorscheme(theme)
