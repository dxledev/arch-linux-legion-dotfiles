local bamboo_colors = {
  comment = "#6F736E",
}

return {
  {
    "ribru17/bamboo.nvim",
    name = "bamboo",
    lazy = true,
    priority = 1000,

    init = function()
      local function bamboo_highlights()
        vim.api.nvim_set_hl(0, "Comment", {
          fg = bamboo_colors.comment,
          italic = true,
        })

        vim.api.nvim_set_hl(0, "@comment", {
          fg = bamboo_colors.comment,
          italic = true,
        })

        -- Native Neovim tabline
        vim.api.nvim_set_hl(0, "TabLine", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "TabLineFill", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "TabLineSel", {
          bg = "NONE",
        })

        -- bufferline.nvim tabs
        vim.api.nvim_set_hl(0, "BufferLineFill", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineBackground", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineBuffer", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineBufferSelected", {
          bg = "NONE",
          bold = true,
        })

        vim.api.nvim_set_hl(0, "BufferLineTab", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineTabSelected", {
          bg = "NONE",
          bold = true,
        })

        vim.api.nvim_set_hl(0, "BufferLineSeparator", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineSeparatorSelected", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineCloseButton", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineCloseButtonSelected", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineModified", {
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "BufferLineModifiedSelected", {
          bg = "NONE",
        })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "bamboo",
        callback = function()
          vim.schedule(bamboo_highlights)
        end,
      })
    end,
  },
}
