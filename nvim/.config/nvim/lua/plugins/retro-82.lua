return {
  {
    "OldJobobo/retro-82.nvim",
    name = "retro-82",
    lazy = true,
    priority = 1000,

    init = function()
      local palette = {
        white = "#f6dcac",
        gray = "#14474f",
      }

      local function retro82_highlights()
        -- Parameter / inlay hints
        vim.api.nvim_set_hl(0, "LspInlayHint", {
          fg = palette.gray,
          bg = "NONE",
          italic = true,
        })

        -- Active parameter in signature popup
        vim.api.nvim_set_hl(0, "LspSignatureActiveParameter", {
          fg = palette.gray,
          bold = true,
        })

        -- Parentheses / brackets: (), {}, [], <>
        vim.api.nvim_set_hl(0, "@punctuation.bracket", {
          fg = palette.white,
        })

        vim.api.nvim_set_hl(0, "@punctuation.bracket.cpp", {
          fg = palette.white,
        })

        -- Fallback group some themes use for brackets
        vim.api.nvim_set_hl(0, "Delimiter", {
          fg = palette.white,
        })

        -- Rainbow delimiter fallback
        for i = 1, 7 do
          vim.api.nvim_set_hl(0, "RainbowDelimiter" .. i, {
            fg = palette.white,
          })
        end

        -- bufferline.nvim top tab row
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

        -- Neo-tree explorer/title/header background fix
        for _, group_name in ipairs({
          "NeoTreeNormal",
          "NeoTreeNormalNC",
          "NeoTreeEndOfBuffer",
          "NeoTreeWinSeparator",
          "NeoTreeTitleBar",
          "NeoTreeFloatTitle",
          "NeoTreeFloatBorder",
          "NeoTreeTabActive",
          "NeoTreeTabInactive",
          "NeoTreeTabSeparatorActive",
          "NeoTreeTabSeparatorInactive",
          "NeoTreeCursorLine",
          "NeoTreeStatusLine",
          "NeoTreeStatusLineNC",
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

        -- Keep the Explorer title readable after removing its background
        vim.api.nvim_set_hl(0, "NeoTreeTitleBar", {
          fg = palette.white,
          bg = "NONE",
          bold = true,
        })

        -- Snacks picker/explorer title fallback, safe if unused
        vim.api.nvim_set_hl(0, "SnacksPickerTitle", {
          fg = palette.white,
          bg = "NONE",
          bold = true,
        })

        vim.api.nvim_set_hl(0, "SnacksPickerBorder", {
          fg = palette.white,
          bg = "NONE",
        })

        -- Snacks explorer / picker header fix
        for _, group_name in ipairs({
          "SnacksPicker",
          "SnacksPickerBorder",
          "SnacksPickerTitle",

          "SnacksPickerInput",
          "SnacksPickerInputBorder",
          "SnacksPickerInputTitle",

          "SnacksPickerList",
          "SnacksPickerListBorder",
          "SnacksPickerListTitle",

          "SnacksPickerPreview",
          "SnacksPickerPreviewBorder",
          "SnacksPickerPreviewTitle",

          "SnacksPickerBox",
          "SnacksPickerBoxBorder",
          "SnacksPickerBoxTitle",
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

        -- Force the visible "Explorer" title itself
        for _, group_name in ipairs({
          "SnacksPickerTitle",
          "SnacksPickerInputTitle",
          "SnacksPickerListTitle",
          "SnacksPickerBoxTitle",
        }) do
          vim.api.nvim_set_hl(0, group_name, {
            fg = palette.white,
            bg = "NONE",
            bold = true,
          })
        end

        -- Noice command line popup fix
        for _, group_name in ipairs({
          "NoiceCmdline",
          "NoiceCmdlinePopup",
          "NoiceCmdlinePopupBorder",
          "NoiceCmdlinePopupBorderSearch",
          "NoiceCmdlinePopupBorderCmdline",
          "NoiceCmdlinePopupBorderFilter",
          "NoiceCmdlinePopupBorderLua",
          "NoiceCmdlinePopupBorderHelp",
          "NoiceCmdlinePopupBorderInput",
          "NoiceCmdlinePopupTitle",
          "NoiceCmdlineIcon",
          "NoiceCmdlineIconSearch",
          "NoiceCmdlinePrompt",
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

        -- Force the visible "Cmdline" title itself
        vim.api.nvim_set_hl(0, "NoiceCmdlinePopupTitle", {
          fg = palette.white,
          bg = "NONE",
          bold = true,
        })

        vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", {
          fg = palette.gray,
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "NoiceCmdlineIcon", {
          fg = palette.white,
          bg = "NONE",
        })
      end

      local function schedule_retro82_highlights()
        vim.schedule(retro82_highlights)
        vim.defer_fn(retro82_highlights, 50)
        vim.defer_fn(retro82_highlights, 200)
        vim.defer_fn(retro82_highlights, 500)
        vim.defer_fn(retro82_highlights, 1000)
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "retro-82",
        callback = schedule_retro82_highlights,
      })

      vim.api.nvim_create_autocmd("CmdlineEnter", {
        callback = schedule_retro82_highlights,
      })
    end,
  },
}
