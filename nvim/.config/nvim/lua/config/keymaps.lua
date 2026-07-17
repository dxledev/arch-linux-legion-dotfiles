-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<C-S-V>", '"+p', { desc = "Paste from system clipboard" })
vim.keymap.set("i", "<C-S-V>", '<C-r>+', { desc = "Paste from system clipboard in insert mode" })
vim.keymap.set("n", "<leader>fg", function()
  require("snacks.picker").grep({
    cwd = require("lazyvim.util").root(),
  })
end, { desc = "Live Grep (Project Root)" })

vim.keymap.set("n", "<leader>t", function()
  require("utils.floatterm").toggle()
end, { desc = "Open floating terminal" })

vim.keymap.set("n", "<C-S-v>", "<C-v>", {
  desc = "Visual Block Mode",
})

vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>")

