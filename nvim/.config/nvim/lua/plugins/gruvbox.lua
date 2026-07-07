return {
  {
    "ellisonleao/gruvbox.nvim",
    name = "gruvbox",
    lazy = true,
    priority = 1000,

    opts = {
      transparent_mode = true,
    },

    config = function(_, opts)
      require("gruvbox").setup(opts)

      local function gruvbox_bufferline_fix()
        -- Empty space to the right of bufferline tabs
        vim.api.nvim_set_hl(0, "BufferLineFill", {
          bg = "NONE",
        })

        -- Native tabline fallback
        vim.api.nvim_set_hl(0, "TabLineFill", {
          bg = "NONE",
        })

        -- Bufferline offset/side areas
        vim.api.nvim_set_hl(0, "BufferLineOffset", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineOffsetSeparator", {
          bg = "NONE",
          fg = "NONE",
        })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "gruvbox",
        callback = function()
          vim.schedule(gruvbox_bufferline_fix)
          vim.defer_fn(gruvbox_bufferline_fix, 50)
          vim.defer_fn(gruvbox_bufferline_fix, 200)
        end,
      })
    end,
  },
}
