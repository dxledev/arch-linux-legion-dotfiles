return {
  {
    "somerocketeer/bauhaus.nvim",
    name = "bauhaus-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("bauhaus").setup({ transparent = false })
      vim.cmd.colorscheme("bauhaus")
    end,
  },
}
