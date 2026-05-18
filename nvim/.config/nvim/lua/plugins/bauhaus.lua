return {
  {
    "somerocketeer/bauhaus.nvim",
    name = "bauhaus",
    lazy = true,
    priority = 1000,
    config = function()
      require("bauhaus").setup({ transparent = false })
    end,
  },
}
