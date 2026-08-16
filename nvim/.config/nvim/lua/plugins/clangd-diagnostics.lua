return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          handlers = {
            ["textDocument/publishDiagnostics"] = function(...)
              return require("config.clangd-diagnostics").publish_diagnostics(...)
            end,
          },
        },
      },
    },
  },
}
