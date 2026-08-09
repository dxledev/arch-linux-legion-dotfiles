return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      for _, parser in ipairs({
        "html",
        "javascript",
        "tsx",
        "typescript",
        "xml",
      }) do
        if not vim.tbl_contains(opts.ensure_installed, parser) then
          table.insert(opts.ensure_installed, parser)
        end
      end
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    opts = {
      opts = {
        enable_close = true,
        enable_rename = true,
      },
    },
    config = function(_, opts)
      require("nvim-ts-autotag").setup(opts)
      require("config.web-tag-rename").setup()
    end,
  },
}
