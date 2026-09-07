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

vim.keymap.set("n", "<leader>cw", "<cmd>%s/\\s\\+$//e<cr>", {
  desc = "Remove Trailing Whitespace",
})

vim.keymap.set("n", "<leader>bh", "<cmd>BufferLineMovePrev<cr>", {
  desc = "Move buffer left",
})

vim.keymap.set("n", "<leader>bl", "<cmd>BufferLineMoveNext<cr>", {
  desc = "Move buffer right",
})

local window_resize_ratio = 0.05

local function resize_window_width(direction)
  local resize_columns = math.max(1, math.floor(vim.o.columns * window_resize_ratio + 0.5))
  vim.cmd(string.format("vertical resize %+d", direction * resize_columns))
end

local function increase_window_width()
  resize_window_width(1)
end

local function decrease_window_width()
  resize_window_width(-1)
end

vim.keymap.set("n", "<C-w><", increase_window_width, { desc = "Increase window width by 5%" })
vim.keymap.set("n", "<C-,>", increase_window_width, { desc = "Increase window width by 5%" })

vim.keymap.set("n", "<C-w>>", decrease_window_width, { desc = "Decrease window width by 5%" })
vim.keymap.set("n", "<C-.>", decrease_window_width, { desc = "Decrease window width by 5%" })
