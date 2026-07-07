local opts = vim.deepcopy(require("config.themes.crimson"))

opts.name = "crimson"

require("aether.config").setup(opts)
require("aether").load()

local function crimson_bufferline_transparent()
  local bg = "NONE"

  local groups = {
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
  }

  for _, group in ipairs(groups) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, {
      name = group,
      link = false,
    })

    if ok then
      hl.bg = nil
      hl.ctermbg = nil

      vim.api.nvim_set_hl(0, group, vim.tbl_extend("force", hl, {
        bg = bg,
      }))
    end
  end
end

vim.schedule(crimson_bufferline_transparent)
vim.defer_fn(crimson_bufferline_transparent, 50)
vim.defer_fn(crimson_bufferline_transparent, 200)
