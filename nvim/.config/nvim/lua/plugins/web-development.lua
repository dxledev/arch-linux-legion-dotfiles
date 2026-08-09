local web_filetypes = {
  "css",
  "html",
  "javascript",
  "javascriptreact",
  "less",
  "sass",
  "scss",
  "typescript",
  "typescriptreact",
}

return {
  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      opts.keymap = opts.keymap or {}
      opts.keymap["<CR>"] = {
        "accept",
        function()
          return require("config.web-enter").expand_empty_tag()
        end,
        "fallback",
      }
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "css",
        "scss",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        cssls = {},
        eslint = {
          settings = {
            rulesCustomizations = {
              { rule = "no-unused-vars", severity = "warn" },
              { rule = "@typescript-eslint/no-unused-vars", severity = "warn" },
            },
          },
        },
        html = {},
        emmet_language_server = {
          filetypes = web_filetypes,
        },
      },
    },
  },
}
