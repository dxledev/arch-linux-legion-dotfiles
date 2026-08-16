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
        function(cmp)
          return require("config.web-enter").accept_completion(cmp)
        end,
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
        cssls = {
          handlers = {
            ["textDocument/diagnostic"] = function(...)
              return require("config.tailwind-css").document_diagnostics(...)
            end,
            ["textDocument/publishDiagnostics"] = function(...)
              return require("config.tailwind-css").publish_diagnostics(...)
            end,
          },
        },
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
