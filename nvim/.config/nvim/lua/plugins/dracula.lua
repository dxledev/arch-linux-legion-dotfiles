return {
  {
    "Mofiqul/dracula.nvim",
    name = "dracula",
    lazy = true,
    priority = 1000,

    opts = {
      transparent_bg = true,
    },

    config = function(_, opts)
      require("dracula").setup(opts)

      local function dracula_bufferline_fix()
        -- Empty space to the right of the tabs
        vim.api.nvim_set_hl(0, "BufferLineFill", {
          bg = "NONE",
        })

        -- Native tabline fallback
        vim.api.nvim_set_hl(0, "TabLineFill", {
          bg = "NONE",
        })

        -- Sometimes bufferline uses this for offsets/side areas
        vim.api.nvim_set_hl(0, "BufferLineOffset", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineOffsetSeparator", {
          bg = "NONE",
          fg = "NONE",
        })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "dracula",
        callback = function()
          vim.schedule(dracula_bufferline_fix)
          vim.defer_fn(dracula_bufferline_fix, 50)
          vim.defer_fn(dracula_bufferline_fix, 200)
        end,
      })
    end,
  },
}
