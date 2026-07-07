return {
  {
    "neanias/everforest-nvim",
    name = "everforest",
    priority = 1000,

    opts = {
      background = "soft",

      on_highlights = function(hl, palette)
        -- Parameter / inlay hints
        hl.LspInlayHint = {
          fg = palette.grey1,
          bg = "NONE",
          italic = true,
        }

        -- Empty space to the right of bufferline tabs
        hl.BufferLineFill = {
          bg = "NONE",
        }

        -- Native tabline fallback
        hl.TabLineFill = {
          bg = "NONE",
        }

        -- Bufferline offset/side areas
        hl.BufferLineOffset = {
          bg = "NONE",
        }

        hl.BufferLineOffsetSeparator = {
          bg = "NONE",
          fg = "NONE",
        }
      end,
    },

    config = function(_, opts)
      require("everforest").setup(opts)

      local function everforest_bufferline_fix()
        vim.api.nvim_set_hl(0, "BufferLineFill", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "TabLineFill", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineOffset", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineOffsetSeparator", {
          bg = "NONE",
          fg = "NONE",
        })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "everforest",
        callback = function()
          vim.schedule(everforest_bufferline_fix)
          vim.defer_fn(everforest_bufferline_fix, 50)
          vim.defer_fn(everforest_bufferline_fix, 200)
        end,
      })
    end,
  },
}
