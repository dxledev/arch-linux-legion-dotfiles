-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.filetype.add({
  extension = {
    tpp = "cpp.tpp",
  },
})
vim.treesitter.language.register("cpp", "cpp.tpp")

vim.g.autoformat = false

local groups = {
  "Normal",
  "NormalNC",
  "SignColumn",
  "EndOfBuffer",

  "NormalFloat",
  "FloatBorder",

  "NeoTreeNormal",
  "NeoTreeNormalNC",
  "NeoTreeEndOfBuffer",
  "NeoTreeWinSeparator",
}

local function force_transparent()
  for _, group in ipairs(groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
    if ok then
      hl.bg = nil
      vim.api.nvim_set_hl(0, group, hl)
    end
  end
end

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = force_transparent,
})

force_transparent()
