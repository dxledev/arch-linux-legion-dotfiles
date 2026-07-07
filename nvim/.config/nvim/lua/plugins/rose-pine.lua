return {
  "rose-pine/neovim",
  name = "rose-pine",
  lazy = false,
  priority = 1000,

  opts = {
    variant = "main",
    dark_variant = "main",
    disable_background = true,
    styles = {
      bold = true,
      italic = true,
    },
  },

  config = function(_, opts)
    require("rose-pine").setup(opts)

    local function rose_pine_fixes()
      -- Main transparency
      vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE" })

      -- Native Neovim tabline
      vim.api.nvim_set_hl(0, "TabLine", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "TabLineSel", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "TabLineFill", { bg = "NONE" })

      -- bufferline.nvim top tab row
      for _, group_name in ipairs({
        "BufferLineFill",
        "BufferLineBackground",

        "BufferLineBuffer",
        "BufferLineBufferVisible",
        "BufferLineBufferSelected",

        "BufferLineTab",
        "BufferLineTabSelected",
        "BufferLineTabClose",

        "BufferLineCloseButton",
        "BufferLineCloseButtonVisible",
        "BufferLineCloseButtonSelected",

        "BufferLineSeparator",
        "BufferLineSeparatorVisible",
        "BufferLineSeparatorSelected",

        "BufferLineIndicatorSelected",

        "BufferLineModified",
        "BufferLineModifiedVisible",
        "BufferLineModifiedSelected",

        "BufferLineDuplicate",
        "BufferLineDuplicateVisible",
        "BufferLineDuplicateSelected",

        "BufferLineNumbers",
        "BufferLineNumbersVisible",
        "BufferLineNumbersSelected",

        "BufferLinePick",
        "BufferLinePickVisible",
        "BufferLinePickSelected",

        "BufferLineOffset",
        "BufferLineOffsetSeparator",
        "BufferLineTruncMarker",
      }) do
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, {
          name = group_name,
          link = false,
        })

        if ok then
          hl.bg = nil
          hl.ctermbg = nil

          vim.api.nvim_set_hl(0, group_name, vim.tbl_extend("force", hl, {
            bg = "NONE",
          }))
        end
      end
    end

    local function schedule_rose_pine_fixes()
      vim.schedule(rose_pine_fixes)
      vim.defer_fn(rose_pine_fixes, 50)
      vim.defer_fn(rose_pine_fixes, 200)
      vim.defer_fn(rose_pine_fixes, 500)
      vim.defer_fn(rose_pine_fixes, 1000)
    end

    local group = vim.api.nvim_create_augroup("RosePineTransparency", {
      clear = true,
    })

    vim.api.nvim_create_autocmd("ColorScheme", {
      group = group,
      pattern = {
        "rose-pine",
        "rose-pine-main",
        "rose-pine-moon",
        "rose-pine-dawn",
      },
      callback = schedule_rose_pine_fixes,
    })
  end,
}
