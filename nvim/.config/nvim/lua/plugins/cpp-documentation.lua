return {
  {
    "nvim-treesitter/nvim-treesitter",
    init = function()
      require("config.cpp-documentation").setup()
    end,
    opts = function(_, opts)
      if not vim.tbl_contains(opts.ensure_installed, "doxygen") then
        table.insert(opts.ensure_installed, "doxygen")
      end
    end,
  },
}
