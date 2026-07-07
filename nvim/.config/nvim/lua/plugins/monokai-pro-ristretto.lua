return {
  {
    "gthelding/monokai-pro.nvim",
    name = "monokai-pro",
    lazy = true,
    priority = 1000,

    config = function()
      require("monokai-pro").setup({
        filter = "ristretto",

        override = function()
          return {
            NonText = { fg = "#948a8b" },

            MiniIconsGrey = { fg = "#948a8b" },
            MiniIconsRed = { fg = "#fd6883" },
            MiniIconsBlue = { fg = "#85dacc" },
            MiniIconsGreen = { fg = "#adda78" },
            MiniIconsYellow = { fg = "#f9cc6c" },
            MiniIconsOrange = { fg = "#f38d70" },
            MiniIconsPurple = { fg = "#a8a9eb" },
            MiniIconsAzure = { fg = "#a8a9eb" },
            MiniIconsCyan = { fg = "#85dacc" },

            -- Native tabline fallback
            TabLine = { bg = "NONE" },
            TabLineSel = { bg = "NONE" },
            TabLineFill = { bg = "NONE" },

            -- bufferline.nvim top tab row
            BufferLineFill = { bg = "NONE" },
            BufferLineBackground = { bg = "NONE" },
            BufferLineBuffer = { bg = "NONE" },
            BufferLineBufferVisible = { bg = "NONE" },
            BufferLineBufferSelected = { bg = "NONE", bold = true },

            BufferLineTab = { bg = "NONE" },
            BufferLineTabSelected = { bg = "NONE", bold = true },
            BufferLineTabClose = { bg = "NONE" },

            BufferLineCloseButton = { bg = "NONE" },
            BufferLineCloseButtonVisible = { bg = "NONE" },
            BufferLineCloseButtonSelected = { bg = "NONE" },

            BufferLineSeparator = { bg = "NONE" },
            BufferLineSeparatorVisible = { bg = "NONE" },
            BufferLineSeparatorSelected = { bg = "NONE" },

            BufferLineIndicatorSelected = { bg = "NONE" },

            BufferLineModified = { bg = "NONE" },
            BufferLineModifiedVisible = { bg = "NONE" },
            BufferLineModifiedSelected = { bg = "NONE" },

            BufferLineDuplicate = { bg = "NONE" },
            BufferLineDuplicateVisible = { bg = "NONE" },
            BufferLineDuplicateSelected = { bg = "NONE" },

            BufferLineNumbers = { bg = "NONE" },
            BufferLineNumbersVisible = { bg = "NONE" },
            BufferLineNumbersSelected = { bg = "NONE" },

            BufferLinePick = { bg = "NONE" },
            BufferLinePickVisible = { bg = "NONE" },
            BufferLinePickSelected = { bg = "NONE" },

            BufferLineOffset = { bg = "NONE" },
            BufferLineOffsetSeparator = { bg = "NONE", fg = "NONE" },
            BufferLineTruncMarker = { bg = "NONE" },
          }
        end,
      })

      local function ristretto_bufferline_fix()
        for _, group_name in ipairs({
          "TabLine",
          "TabLineSel",
          "TabLineFill",

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

      local function schedule_ristretto_fix()
        vim.schedule(ristretto_bufferline_fix)
        vim.defer_fn(ristretto_bufferline_fix, 50)
        vim.defer_fn(ristretto_bufferline_fix, 200)
        vim.defer_fn(ristretto_bufferline_fix, 500)
        vim.defer_fn(ristretto_bufferline_fix, 1000)
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = {
          "monokai-pro",
          "monokai-pro-ristretto",
          "ristretto",
        },
        callback = schedule_ristretto_fix,
      })
    end,
  },
}
