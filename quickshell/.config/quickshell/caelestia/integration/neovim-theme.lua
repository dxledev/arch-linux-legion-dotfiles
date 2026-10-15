vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.o.background = theme_mode
vim.o.termguicolors = true
vim.g.colors_name = "desktop-dynamic"
vim.g.desktop_dynamic_variant = theme_variant
for index, colour in ipairs(terminal) do vim.g["terminal_color_" .. (index - 1)] = colour end

local function set(names, value)
  for _, name in ipairs(names) do vim.api.nvim_set_hl(0, name, value) end
end

set({ "Normal", "NormalNC", "NormalFloat", "MsgArea" }, { fg = palette.text, bg = "NONE" })
set({ "EndOfBuffer", "SignColumn", "FoldColumn", "NonText", "SpecialKey", "Whitespace", "Conceal" }, { fg = palette.punctuation, bg = "NONE" })
set({ "CursorLine", "CursorColumn", "ColorColumn", "Visual", "VisualNOS", "QuickFixLine" }, { bg = palette.surface1 })
set({ "LineNr", "LineNrAbove", "LineNrBelow" }, { fg = palette.muted, bg = "NONE" })
set({ "CursorLineNr" }, { fg = palette.primary, bold = true, bg = "NONE" })
set({ "StatusLine", "WinBar", "Pmenu", "PmenuExtra", "PmenuKind", "Folded" }, { fg = palette.text, bg = palette.surface0 })
set({ "StatusLineNC", "WinBarNC", "TabLine", "TabLineFill", "LualineInactive" }, { fg = palette.muted, bg = palette.mantle })
set({ "VertSplit", "WinSeparator", "MsgSeparator" }, { fg = palette.punctuation, bg = "NONE" })
set({ "TabLineSel", "CurSearch", "PmenuSel", "PmenuKindSel", "PmenuExtraSel", "PmenuMatchSel", "DiffText" }, { fg = palette.selection_text, bg = palette.primary, bold = true })
set({ "Cursor", "lCursor", "CursorIM", "TermCursor" }, { fg = palette.base, bg = palette.text })
set({ "Title", "Directory", "MoreMsg", "ModeMsg", "Question" }, { fg = palette.primary, bold = true })
set({ "Search", "IncSearch", "Todo" }, { fg = palette.selection_text, bg = palette.yellow, bold = true })
set({ "MatchParen" }, { fg = palette.primary, bold = true, underline = true })
set({ "PmenuSbar" }, { bg = palette.surface1 })
set({ "PmenuThumb" }, { bg = palette.primary })
set({ "FloatBorder", "FloatTitle" }, { fg = palette.primary, bg = "NONE", bold = true })
set({ "Error", "ErrorMsg", "DiagnosticError" }, { fg = palette.red, bold = true })
set({ "WarningMsg", "DiagnosticWarn" }, { fg = palette.yellow, bold = true })
set({ "DiagnosticInfo" }, { fg = palette.blue })
set({ "DiagnosticHint", "DiagnosticOk" }, { fg = palette.teal })
for _, severity in ipairs({ "Error", "Warn", "Info", "Hint", "Ok" }) do
  for _, kind in ipairs({ "VirtualText", "Floating", "Sign" }) do
    set({ "Diagnostic" .. kind .. severity }, { link = "Diagnostic" .. severity })
  end
end
set({ "DiagnosticUnnecessary" }, { fg = palette.muted })
set({ "DiagnosticUnderlineError", "SpellBad" }, { sp = palette.red, undercurl = true })
set({ "DiagnosticUnderlineWarn", "SpellRare" }, { sp = palette.yellow, undercurl = true })
set({ "DiagnosticUnderlineInfo", "SpellCap" }, { sp = palette.blue, undercurl = true })
set({ "DiagnosticUnderlineHint", "SpellLocal" }, { sp = palette.teal, undercurl = true })
set({ "DiffAdd", "Added", "GitSignsAdd" }, { fg = palette.green, bg = "NONE" })
set({ "DiffChange", "Changed", "GitSignsChange" }, { fg = palette.yellow, bg = "NONE" })
set({ "DiffDelete", "Removed", "GitSignsDelete" }, { fg = palette.red, bg = "NONE" })
set({ "Comment", "@comment", "@comment.documentation", "@lsp.type.comment" }, { fg = palette.muted, italic = true })
set({ "LspInlayHint" }, { fg = palette.muted })
set({ "Constant", "@constant", "@constant.builtin", "@number", "@number.float", "@boolean", "Number", "Boolean", "Float" }, { fg = palette.peach })
set({ "String", "Character", "@string", "@string.escape", "@character", "@markup.raw" }, { fg = palette.green })
set({ "Identifier", "@variable", "@variable.builtin", "@variable.parameter", "@variable.member", "@parameter", "@property", "@custom.template_argument", "@custom.template_argument.cpp", "@lsp.type.variable", "@lsp.type.parameter", "@lsp.type.property" }, { fg = palette.text })
set({ "Function", "@function", "@function.call", "@function.builtin", "@function.method", "@function.method.call", "@method", "@method.call", "@lsp.type.function", "@lsp.type.method" }, { fg = palette.blue })
set({ "Statement", "Keyword", "Conditional", "Repeat", "Label", "Operator", "Exception", "@keyword", "@keyword.function", "@keyword.return", "@operator", "@lsp.type.keyword", "@lsp.type.operator" }, { fg = palette.mauve })
set({ "PreProc", "Include", "Define", "Macro", "PreCondit", "@keyword.directive", "@keyword.import", "@lsp.type.macro" }, { fg = palette.pink })
set({ "Type", "StorageClass", "Structure", "Typedef", "@type", "@type.builtin", "@type.definition", "@constructor", "@module", "@namespace", "@namespace.definition", "@namespace.alias", "@lsp.type.type", "@lsp.type.class", "@lsp.type.struct", "@lsp.type.enum", "@lsp.type.interface", "@lsp.type.namespace", "@lsp.type.typeParameter" }, { fg = palette.teal })
set({ "Special", "SpecialChar", "SpecialComment", "Tag", "@tag", "@tag.attribute", "@markup.link", "@markup.link.url" }, { fg = palette.sky })
set({ "Delimiter", "@punctuation", "@punctuation.delimiter", "@punctuation.bracket", "@punctuation.special", "@tag.delimiter", "@custom.array_bracket", "@custom.array_bracket.cpp", "@markup.list" }, { fg = palette.punctuation })
set({ "Underlined" }, { fg = palette.blue, underline = true })
set({ "@markup.heading" }, { fg = palette.primary, bold = true })
set({ "@markup.strong" }, { fg = palette.text, bold = true })
set({ "@markup.italic" }, { fg = palette.text, italic = true })
set({ "@markup.strikethrough" }, { fg = palette.text, strikethrough = true })
set({ "WhichKey", "TelescopePromptTitle", "TelescopeResultsTitle", "LazyH1" }, { fg = palette.selection_text, bg = palette.primary, bold = true })
set({ "WhichKeyNormal", "TelescopeNormal", "TelescopePromptNormal", "TelescopeResultsNormal", "SnacksNormal" }, { fg = palette.text, bg = "NONE" })
set({ "WhichKeyBorder", "TelescopeBorder", "SnacksWin" }, { fg = palette.primary, bg = "NONE" })
set({ "CmpItemAbbrMatch", "CmpItemAbbrMatchFuzzy", "PmenuMatch" }, { fg = palette.primary, bold = true })
set({ "CmpItemKindFunction", "CmpItemKindMethod" }, { fg = palette.blue })
set({ "CmpItemKindKeyword", "CmpItemKindProperty" }, { fg = palette.mauve })
set({ "CmpItemKindVariable", "CmpItemKindText" }, { fg = palette.text })
set({ "LualineNormal" }, { fg = palette.selection_text, bg = palette.primary, bold = true })
set({ "LualineInsert" }, { fg = palette.selection_text, bg = palette.green, bold = true })
set({ "LualineVisual" }, { fg = palette.selection_text, bg = palette.mauve, bold = true })
set({ "LualineReplace" }, { fg = palette.selection_text, bg = palette.red, bold = true })
set({ "LualineCommand" }, { fg = palette.selection_text, bg = palette.yellow, bold = true })
