return {
	{
		"Biscuit-Theme/nvim",
		name = "biscuit",
		priority = 1000,
		config = function()
			local function fix_popup_highlights()
				if vim.g.colors_name ~= "biscuit" then
					return
				end

				-- Force popup/float UI to a consistent palette after any colorscheme/plugin reload.
				local bg = "#1A1515"
				local light_bg = "#453636"
				local fg = "#ffe9c7"
				local border = "#725a5a"
				local accent = "#f07342"
				local indent = "#453636"
				local scope = "#725a5a"

				vim.api.nvim_set_hl(0, "NormalFloat", { bg = bg, fg = fg })
				vim.api.nvim_set_hl(0, "FloatBorder", { bg = bg, fg = border })
				vim.api.nvim_set_hl(0, "Pmenu", { bg = bg, fg = fg })
				vim.api.nvim_set_hl(0, "PmenuSel", { bg = border, fg = fg, bold = true })
				vim.api.nvim_set_hl(0, "PmenuSbar", { bg = bg })
				vim.api.nvim_set_hl(0, "PmenuThumb", { bg = border })
				vim.api.nvim_set_hl(0, "PmenuKind", { bg = bg, fg = accent })
				vim.api.nvim_set_hl(0, "PmenuExtra", { bg = bg, fg = border })
				vim.api.nvim_set_hl(0, "PmenuKindSel", { bg = border, fg = accent, bold = true })
				vim.api.nvim_set_hl(0, "PmenuExtraSel", { bg = border, fg = fg, bold = true })
				vim.api.nvim_set_hl(0, "WildMenu", { bg = border, fg = fg, bold = true })
				vim.api.nvim_set_hl(0, "WildSel", { bg = border, fg = fg, bold = true })

				-- blink.cmp (used for :cmdline completion in your setup)
				vim.api.nvim_set_hl(0, "BlinkCmpMenu", { bg = light_bg, fg = fg })
				vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { bg = light_bg, fg = border })
				vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { bg = border, fg = fg, bold = true })
				vim.api.nvim_set_hl(0, "BlinkCmpScrollBarGutter", { bg = light_bg })
				vim.api.nvim_set_hl(0, "BlinkCmpScrollBarThumb", { bg = border })
				vim.api.nvim_set_hl(0, "BlinkCmpDoc", { bg = light_bg, fg = fg })
				vim.api.nvim_set_hl(0, "BlinkCmpDocBorder", { bg = light_bg, fg = border })
				vim.api.nvim_set_hl(0, "BlinkCmpDocSeparator", { bg = light_bg, fg = border })
				vim.api.nvim_set_hl(0, "BlinkCmpLabel", { fg = fg })
				vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { fg = accent, bold = true })
				vim.api.nvim_set_hl(0, "BlinkCmpLabelDetail", { fg = border })
				vim.api.nvim_set_hl(0, "BlinkCmpLabelDescription", { fg = border })
				vim.api.nvim_set_hl(0, "BlinkCmpSource", { fg = accent })
				vim.api.nvim_set_hl(0, "BlinkCmpKind", { fg = accent })
				for _, kind in ipairs({
					"Text",
					"Method",
					"Function",
					"Constructor",
					"Field",
					"Variable",
					"Class",
					"Interface",
					"Module",
					"Property",
					"Unit",
					"Value",
					"Enum",
					"Keyword",
					"Snippet",
					"Color",
					"File",
					"Reference",
					"Folder",
					"EnumMember",
					"Constant",
					"Struct",
					"Event",
					"Operator",
					"TypeParameter",
				}) do
					vim.api.nvim_set_hl(0, "BlinkCmpKind" .. kind, { fg = accent })
				end

				-- nvim-cmp compatibility groups (safe if not used)
				vim.api.nvim_set_hl(0, "CmpItemAbbr", { fg = fg })
				vim.api.nvim_set_hl(0, "CmpItemAbbrMatch", { fg = accent, bold = true })
				vim.api.nvim_set_hl(0, "CmpItemMenu", { fg = border })
				vim.api.nvim_set_hl(0, "CmpItemKind", { fg = accent })
				for _, kind in ipairs({
					"Text",
					"Method",
					"Function",
					"Constructor",
					"Field",
					"Variable",
					"Class",
					"Interface",
					"Module",
					"Property",
					"Unit",
					"Value",
					"Enum",
					"Keyword",
					"Snippet",
					"Color",
					"File",
					"Reference",
					"Folder",
					"EnumMember",
					"Constant",
					"Struct",
					"Event",
					"Operator",
					"TypeParameter",
				}) do
					vim.api.nvim_set_hl(0, "CmpItemKind" .. kind, { fg = accent })
				end

				-- noice cmdline popup groups (safe if unused)
				vim.api.nvim_set_hl(0, "NoiceCmdlinePopup", { bg = bg, fg = fg })
				vim.api.nvim_set_hl(0, "NoiceCmdlinePopupBorder", { bg = bg, fg = border })
				vim.api.nvim_set_hl(0, "NoiceCmdlineIcon", { fg = accent })

				-- indent-blankline/ibl guides (right of line numbers)
				vim.api.nvim_set_hl(0, "IblIndent", { fg = indent, nocombine = true })
				vim.api.nvim_set_hl(0, "IblWhitespace", { fg = indent, nocombine = true })
				vim.api.nvim_set_hl(0, "IblScope", { fg = scope, nocombine = true })
				vim.api.nvim_set_hl(0, "IndentBlanklineChar", { fg = indent, nocombine = true })
				vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { fg = scope, nocombine = true })

				-- Rainbow indent fallback groups if enabled by plugin config.
				vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#F07342" })
				vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E39C45" })
				vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#614F76" })
				vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#959A6B" })
				vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#768F80" })
				vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#7B3D79" })
				vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#AE3F82" })

				-- Git/diff gutter bars in signcolumn.
				vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })
				vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#2d2424", fg = "#768F80" })
				vim.api.nvim_set_hl(0, "DiffChange", { bg = "#2d2424", fg = "#756D94" })
				vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#2d2424", fg = "#F07342" })
				vim.api.nvim_set_hl(0, "DiffText", { bg = "#453636", fg = "#DCC9BC", bold = true })
				vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#768F80", bg = "NONE" })
				vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#756D94", bg = "NONE" })
				vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#F07342", bg = "NONE" })
				vim.api.nvim_set_hl(0, "GitSignsTopdelete", { fg = "#F07342", bg = "NONE" })
				vim.api.nvim_set_hl(0, "GitSignsChangedelete", { fg = "#E39C45", bg = "NONE" })
				vim.api.nvim_set_hl(0, "MiniDiffSignAdd", { fg = "#768F80", bg = "NONE" })
				vim.api.nvim_set_hl(0, "MiniDiffSignChange", { fg = "#756D94", bg = "NONE" })
				vim.api.nvim_set_hl(0, "MiniDiffSignDelete", { fg = "#F07342", bg = "NONE" })

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

        -- LazyVim / Snacks dashboard
        vim.api.nvim_set_hl(0, "SnacksDashboardHeader", {
          fg = "#AE3F82",
          bg = "NONE",
          bold = true,
        })

        vim.api.nvim_set_hl(0, "SnacksDashboardIcon", {
          fg = accent,
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "SnacksDashboardDesc", {
          fg = fg,
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "SnacksDashboardKey", {
          fg = accent,
          bg = "NONE",
          bold = true,
        })

        vim.api.nvim_set_hl(0, "SnacksDashboardSpecial", {
          fg = "#E39C45",
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "SnacksDashboardFooter", {
          fg = border,
          bg = "NONE",
          italic = true,
        })

        vim.api.nvim_set_hl(0, "SnacksDashboardDir", {
          fg = border,
          bg = "NONE",
        })

        -- Old dashboard.nvim / alpha fallback groups
        vim.api.nvim_set_hl(0, "DashboardHeader", {
          fg = "#AE3F82",
          bg = "NONE",
          bold = true,
        })

        vim.api.nvim_set_hl(0, "DashboardCenter", {
          fg = fg,
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "DashboardShortCut", {
          fg = accent,
          bg = "NONE",
          bold = true,
        })

        vim.api.nvim_set_hl(0, "DashboardFooter", {
          fg = border,
          bg = "NONE",
          italic = true,
        })

        -- Neo-tree / file explorer icons
        vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", {
          fg = "#E39C45",
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", {
          fg = fg,
          bg = "NONE",
        })

        vim.api.nvim_set_hl(0, "NeoTreeRootName", {
          fg = accent,
          bg = "NONE",
          bold = true,
        })

        vim.api.nvim_set_hl(0, "NeoTreeFileIcon", {
          fg = accent,
          bg = "NONE",
        })

        -- Neo-tree git/status icons
        vim.api.nvim_set_hl(0, "NeoTreeGitAdded", { fg = "#768F80", bg = "NONE" })
        vim.api.nvim_set_hl(0, "NeoTreeGitModified", { fg = "#E39C45", bg = "NONE" })
        vim.api.nvim_set_hl(0, "NeoTreeGitDeleted", { fg = "#F07342", bg = "NONE" })
        vim.api.nvim_set_hl(0, "NeoTreeGitUntracked", { fg = "#AE3F82", bg = "NONE" })
        vim.api.nvim_set_hl(0, "NeoTreeGitIgnored", { fg = border, bg = "NONE" })
        vim.api.nvim_set_hl(0, "NeoTreeGitConflict", { fg = "#F07342", bg = "NONE", bold = true })

        local icon_palette = {
          "#F07342", -- orange
          "#E39C45", -- yellow
          "#AE3F82", -- magenta
          "#7B3D79", -- purple
          "#768F80", -- green
          "#959A6B", -- olive
          "#614F76", -- muted purple
          "#ffe9c7", -- cream
        }

        local function color_from_name(name)
          local sum = 0

          for i = 1, #name do
            sum = sum + string.byte(name, i)
          end

          return icon_palette[(sum % #icon_palette) + 1]
        end

        -- nvim-web-devicons: color every filetype icon using your theme palette
        for _, group_name in ipairs(vim.fn.getcompletion("DevIcon", "highlight")) do
          vim.api.nvim_set_hl(0, group_name, {
            fg = color_from_name(group_name),
            bg = "NONE",
          })
        end

        -- mini.icons / LazyVim fallback: color every icon using your theme palette
        for _, group_name in ipairs(vim.fn.getcompletion("MiniIcons", "highlight")) do
          vim.api.nvim_set_hl(0, group_name, {
            fg = color_from_name(group_name),
            bg = "NONE",
          })
        end

			end

			local function schedule_haze_fixes()
        vim.schedule(fix_popup_highlights)
        vim.defer_fn(fix_popup_highlights, 50)
        vim.defer_fn(fix_popup_highlights, 200)
      end

      schedule_haze_fixes()

      local group = vim.api.nvim_create_augroup("OmarchyBiscuitPopupHighlights", { clear = true })

      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = schedule_haze_fixes,
      })

      vim.api.nvim_create_autocmd({ "User" }, {
        group = group,
        pattern = { "BlinkCmpMenuOpen", "BlinkCmpShow" },
        callback = schedule_haze_fixes,
      })
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = nil,
		},
	},
}
