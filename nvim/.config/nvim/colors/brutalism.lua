
-- Brutalism colorscheme for Neovim

vim.cmd("highlight clear")

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end

vim.g.colors_name = "brutalism"
vim.o.background = "dark"

-- Color Palette
local colors = {
    bg      = "#121212",
    fg      = "#ded3d3",
    mantle  = "#1b1717",
    surface = "#241919",
    muted   = "#b89494",
    border  = "#514d4d",
    red     = "#e96565",
    darkred = "#450404",
    deepred = "#630a0a",
    accent  = "#ce5757",
    rose    = "#c87777",
    salmon  = "#d48484",
    blush   = "#cc7a7a",
    pale    = "#e7baba",
    sage    = "#a8b59d",
    ochre   = "#c6a477",
    steel   = "#91a3ad",
    plum    = "#ad90a3",
    punctuation = "#756868",
    inlay   = "#484040",
}

local function hi(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

-- Enable true colors
vim.o.termguicolors = true

-- UI Elements
hi("Normal", { fg = colors.fg, bg = colors.bg })
hi("NormalNC", { fg = colors.fg, bg = colors.bg })
hi("NormalFloat", { fg = colors.fg, bg = colors.bg })
hi("FloatBorder", { fg = colors.muted, bg = colors.bg })
hi("WinSeparator", { fg = colors.border, bg = colors.bg })
hi("VertSplit", { fg = colors.border, bg = colors.bg })
hi("LineNr", { fg = colors.muted, bg = colors.bg })
hi("CursorLine", { bg = colors.mantle })
hi("CursorLineNr", { fg = colors.fg, bold = true })
hi("SignColumn", { bg = colors.bg })
hi("Visual", { bg = colors.surface })
hi("Search", { fg = colors.bg, bg = colors.salmon, bold = true })
hi("IncSearch", { fg = colors.bg, bg = colors.red, bold = true })
hi("MatchParen", { fg = colors.red, bold = true })
hi("Pmenu", { fg = colors.fg, bg = colors.mantle })
hi("PmenuSel", { fg = colors.bg, bg = colors.accent, bold = true })
hi("PmenuThumb", { bg = colors.accent })
hi("StatusLine", { fg = colors.fg, bg = colors.surface })
hi("StatusLineNC", { fg = colors.muted, bg = colors.mantle })

-- Native Neovim tabline
hi("TabLine", { fg = colors.muted, bg = colors.bg })
hi("TabLineSel", { fg = colors.accent, bg = colors.bg, bold = true })
hi("TabLineFill", { bg = colors.bg })
hi("Title", { fg = colors.fg, bold = true })
hi("Directory", { fg = colors.accent, bold = true })
hi("Whitespace", { fg = colors.border })

-- Syntax Highlighting
hi("Comment", { fg = colors.muted, italic = true })
hi("Identifier", { fg = colors.fg })
hi("Function", { fg = colors.steel, bold = true })
hi("Statement", { fg = colors.accent })
hi("Conditional", { fg = colors.accent })
hi("Repeat", { fg = colors.accent })
hi("Operator", { fg = colors.rose })
hi("Keyword", { fg = colors.accent, italic = true })
hi("PreProc", { fg = colors.plum })
hi("Type", { fg = colors.ochre })
hi("Special", { fg = colors.pale })
hi("Underlined", { fg = colors.fg, underline = true })
hi("Todo", { fg = colors.bg, bg = colors.fg, bold = true })
hi("Constant", { fg = colors.pale })
hi("String", { fg = colors.sage })
hi("Character", { fg = colors.sage })
hi("Number", { fg = colors.ochre })
hi("Boolean", { fg = colors.ochre })
hi("Float", { fg = colors.ochre })

-- Diagnostics
hi("Error", { fg = colors.red, bold = true })
hi("WarningMsg", { fg = colors.salmon })
hi("DiagnosticError", { fg = colors.red })
hi("DiagnosticWarn", { fg = colors.pale })
hi("DiagnosticInfo", { fg = colors.salmon })
hi("DiagnosticHint", { fg = colors.blush })
hi("DiagnosticOk", { fg = colors.blush })
hi("DiagnosticUnderlineError", { undercurl = true, sp = colors.red })
hi("DiagnosticUnderlineWarn", { undercurl = true, sp = colors.pale })
hi("DiagnosticUnderlineInfo", { undercurl = true, sp = colors.salmon })
hi("DiagnosticUnderlineHint", { undercurl = true, sp = colors.blush })
hi("DiagnosticVirtualTextError", { fg = colors.red, bg = colors.mantle })
hi("DiagnosticVirtualTextWarn", { fg = colors.pale, bg = colors.mantle })
hi("DiagnosticVirtualTextInfo", { fg = colors.salmon, bg = colors.mantle })
hi("DiagnosticVirtualTextHint", { fg = colors.blush, bg = colors.mantle })

-- Git/Diff
hi("DiffAdd", { fg = colors.blush, bg = colors.mantle })
hi("DiffChange", { fg = colors.salmon, bg = colors.mantle })
hi("DiffDelete", { fg = colors.red, bg = colors.mantle })
hi("DiffText", { fg = colors.fg, bg = colors.surface, bold = true })
hi("GitSignsAdd", { fg = colors.blush })
hi("GitSignsChange", { fg = colors.salmon })
hi("GitSignsDelete", { fg = colors.red })

-- Treesitter
hi("@comment", { link = "Comment" })
hi("@function", { link = "Function" })
hi("@function.builtin", { link = "Function" })
hi("@function.call", { link = "Function" })
hi("@function.method", { link = "Function" })
hi("@function.method.call", { link = "Function" })
hi("@keyword", { link = "Keyword" })
hi("@keyword.function", { link = "Keyword" })
hi("@keyword.operator", { link = "Operator" })
hi("@keyword.directive", { link = "PreProc" })
hi("@keyword.directive.define", { link = "PreProc" })
hi("@keyword.import", { link = "PreProc" })
hi("@type", { link = "Type" })
hi("@type.builtin", { link = "Type" })
hi("@type.definition", { link = "Type" })
hi("@string", { link = "String" })
hi("@string.documentation", { link = "String" })
hi("@string.escape", { fg = colors.pale })
hi("@string.special", { fg = colors.pale })
hi("@number", { link = "Number" })
hi("@boolean", { link = "Boolean" })
hi("@float", { link = "Float" })
hi("@variable", { fg = colors.fg })
hi("@variable.builtin", { fg = colors.rose, italic = true })
hi("@constant", { link = "Constant" })
hi("@constant.builtin", { link = "Constant" })
hi("@punctuation", { fg = colors.punctuation })
hi("@punctuation.bracket", { fg = colors.punctuation })
hi("@punctuation.delimiter", { fg = colors.punctuation })
hi("@punctuation.special", { fg = colors.punctuation })
hi("@punctuation.bracket.cpp", { fg = colors.punctuation })
hi("@punctuation.delimiter.cpp", { fg = colors.punctuation })
hi("@operator", { link = "Operator" })
hi("@variable.parameter", { fg = colors.steel })
hi("@parameter", { fg = colors.steel })
hi("@property", { fg = colors.salmon })
hi("@field", { fg = colors.salmon })
hi("@constructor", { fg = colors.ochre })
hi("@module", { fg = colors.plum })
hi("@namespace", { fg = colors.plum })
hi("@tag", { fg = colors.steel })
hi("@tag.attribute", { fg = colors.salmon })
hi("@tag.delimiter", { fg = colors.punctuation })
hi("@custom.array_bracket", { fg = colors.punctuation })
hi("@custom.array_bracket.cpp", { fg = colors.punctuation })

-- LSP Semantic Tokens
hi("@lsp.type.class", { link = "Type" })
hi("@lsp.type.decorator", { link = "Function" })
hi("@lsp.type.enum", { link = "Type" })
hi("@lsp.type.enumMember", { link = "Constant" })
hi("@lsp.type.function", { link = "Function" })
hi("@lsp.type.interface", { link = "Type" })
hi("@lsp.type.macro", { link = "PreProc" })
hi("@lsp.type.method", { link = "Function" })
hi("@lsp.type.namespace", { link = "@namespace" })
hi("@lsp.type.parameter", { link = "@parameter" })
hi("@lsp.type.property", { link = "@property" })
hi("@lsp.type.struct", { link = "Type" })
hi("@lsp.type.type", { link = "Type" })
hi("@lsp.type.typeParameter", { link = "Type" })
hi("@lsp.type.variable", { link = "@variable" })
hi("LspInlayHint", { fg = colors.inlay, bg = "NONE", italic = true })

-- Telescope
hi("TelescopeBorder", { fg = colors.muted, bg = colors.bg })
hi("TelescopePromptBorder", { fg = colors.accent, bg = colors.bg })
hi("TelescopeResultsBorder", { fg = colors.muted, bg = colors.bg })
hi("TelescopePreviewBorder", { fg = colors.muted, bg = colors.bg })
hi("TelescopeSelection", { fg = colors.bg, bg = colors.accent, bold = true })
hi("TelescopeSelectionCaret", { fg = colors.red })
hi("TelescopeMatching", { fg = colors.red, bold = true })
hi("TelescopePromptPrefix", { fg = colors.accent })

-- Neo-tree
hi("NeoTreeNormal", { fg = colors.fg, bg = colors.bg })
hi("NeoTreeNormalNC", { fg = colors.fg, bg = colors.bg })
hi("NeoTreeRootName", { fg = colors.accent, bold = true })
hi("NeoTreeDirectoryName", { fg = colors.accent })
hi("NeoTreeDirectoryIcon", { fg = colors.accent })
hi("NeoTreeFileNameOpened", { fg = colors.red })
hi("NeoTreeIndentMarker", { fg = colors.muted })
hi("NeoTreeGitAdded", { fg = colors.blush })
hi("NeoTreeGitModified", { fg = colors.salmon })
hi("NeoTreeGitDeleted", { fg = colors.red })

-- Which-key
hi("WhichKey", { fg = colors.accent, bold = true })
hi("WhichKeyGroup", { fg = colors.blush })
hi("WhichKeyDesc", { fg = colors.fg })
hi("WhichKeySeparator", { fg = colors.muted })
hi("WhichKeyFloat", { bg = colors.bg })

-- Notify
hi("NotifyERRORBorder", { fg = colors.red })
hi("NotifyWARNBorder", { fg = colors.salmon })
hi("NotifyINFOBorder", { fg = colors.accent })
hi("NotifyDEBUGBorder", { fg = colors.muted })
hi("NotifyTRACEBorder", { fg = colors.muted })
hi("NotifyERRORIcon", { fg = colors.red })
hi("NotifyWARNIcon", { fg = colors.salmon })
hi("NotifyINFOIcon", { fg = colors.accent })
hi("NotifyDEBUGIcon", { fg = colors.muted })
hi("NotifyTRACEIcon", { fg = colors.muted })
hi("NotifyERRORTitle", { fg = colors.red })
hi("NotifyWARNTitle", { fg = colors.salmon })
hi("NotifyINFOTitle", { fg = colors.accent })
hi("NotifyDEBUGTitle", { fg = colors.muted })
hi("NotifyTRACETitle", { fg = colors.muted })

-- Indent Blankline
hi("IblIndent", { fg = colors.mantle })
hi("IblScope", { fg = colors.muted })

-- Dashboard
hi("DashboardShortCut", { fg = colors.accent })
hi("DashboardHeader", { fg = colors.red })
hi("DashboardCenter", { fg = colors.blush })
hi("DashboardFooter", { fg = colors.muted, italic = true })

-- Terminal colors
vim.g.terminal_color_0 = colors.bg      -- black
vim.g.terminal_color_1 = colors.darkred -- red
vim.g.terminal_color_2 = colors.deepred -- green
vim.g.terminal_color_3 = colors.blush   -- yellow
vim.g.terminal_color_4 = colors.accent  -- blue
vim.g.terminal_color_5 = colors.rose    -- magenta
vim.g.terminal_color_6 = colors.salmon  -- cyan
vim.g.terminal_color_7 = "#d1c7c7"      -- white
vim.g.terminal_color_8 = colors.muted   -- bright black
vim.g.terminal_color_9 = "#9c0909"      -- bright red
vim.g.terminal_color_10 = "#9f1d1d"     -- bright green
vim.g.terminal_color_11 = colors.pale   -- bright yellow
vim.g.terminal_color_12 = colors.red    -- bright blue
vim.g.terminal_color_13 = "#e28585"     -- bright magenta
vim.g.terminal_color_14 = "#eb9696"     -- bright cyan
vim.g.terminal_color_15 = colors.fg     -- bright white
