return {
  {
    "nvim-mini/mini.icons",
    opts = {
      extension = {
        tpp = { glyph = "󰬁", hl = "MiniIconsAzure" },
      },
    },
  },
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          files = {
            hidden = true,
            no_ignore = true,
          },
        },
      },
    },
  },
}
