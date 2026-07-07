return {
  {
    "somerocketeer/bauhaus.nvim",
    name = "bauhaus",
    lazy = true,
    priority = 1000,

    opts = {
      transparent = false,
    },

    init = function()
      local function bauhaus_highlights()
        -- Comments
        vim.api.nvim_set_hl(0, "Comment", {
          fg = "#60666f",
          italic = true,
        })

        vim.api.nvim_set_hl(0, "@comment", {
          fg = "#60666f",
          italic = true,
        })

        vim.api.nvim_set_hl(0, "@comment.documentation", {
          fg = "#60666f",
          italic = true,
        })

        -- Parameter / inlay hints
        vim.api.nvim_set_hl(0, "LspInlayHint", {
          fg = "#52585f",
          bg = "NONE",
          italic = true,
        })

        -- Active parameter in signature popup
        vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", {
          fg = "#60666f",
          bold = true,
        })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "bauhaus",
        callback = function()
          vim.schedule(bauhaus_highlights)
        end,
      })
    end,

    config = function(_, opts)
      require("bauhaus").setup(opts)
    end,
  },
}
