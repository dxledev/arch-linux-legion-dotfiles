return {
  {
    "bjarneo/firesky.nvim",
    name = "firesky",
    lazy = true,
    priority = 1000,

    opts = {
      transparent = false,
    },

    init = function()
      local function firesky_highlights()
        -- Comments
        vim.api.nvim_set_hl(0, "Comment", {
          fg = "#375050",
          italic = true,
        })

        vim.api.nvim_set_hl(0, "@comment", {
          fg = "#375050",
          italic = true,
        })

        vim.api.nvim_set_hl(0, "@comment.documentation", {
          fg = "#375050",
          italic = true,
        })

        -- Parameter / inlay hints
        vim.api.nvim_set_hl(0, "LspInlayHint", {
          fg = "#2c4040",
          bg = "NONE",
          italic = true,
        })

        -- Active parameter in signature popup
        vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", {
          fg = "#375050",
          bold = true,
        })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "firesky",
        callback = function()
          vim.schedule(firesky_highlights)
        end,
      })
    end,

    config = function(_, opts)
      require("firesky").setup(opts)
    end,
  },
}
