local palette = {
  inlay = "#30343a",
  muted = "#4b515b",
  punctuation = "#6d737c",
  soft = "#a7adb6",
  foreground = "#b9bec6",
  coral = "#d94a3a",
  salmon = "#e06a5a",
  orange = "#d08a3a",
  red = "#ff4a4a",
  deep_red = "#c43a3a",
  pale = "#d8dde4",
  white = "#eceff2",
  array_bracket = "#a85b68",
}

local function set_groups(highlights, groups, opts)
  for _, group in ipairs(groups) do
    highlights[group] = opts
  end
end

local function diversify_highlights(highlights)
  set_groups(highlights, {
    "Comment",
    "@comment",
    "@comment.documentation",
    "@lsp.type.comment",
  }, { fg = palette.muted, italic = true })

  set_groups(highlights, {
    "Function",
    "@function",
    "@function.call",
    "@function.method",
    "@function.method.call",
    "@method",
    "@method.call",
    "@lsp.type.function",
    "@lsp.type.method",
  }, { fg = palette.coral, bold = true })

  set_groups(highlights, {
    "Keyword",
    "Statement",
    "Conditional",
    "Repeat",
    "Exception",
    "@keyword",
    "@keyword.conditional",
    "@keyword.exception",
    "@keyword.function",
    "@keyword.repeat",
    "@keyword.storage",
    "@lsp.type.keyword",
    "@lsp.type.modifier",
  }, { fg = palette.red, italic = true })

  set_groups(highlights, {
    "@keyword.return",
    "@keyword.return.cpp",
  }, { fg = palette.array_bracket, italic = true })

  set_groups(highlights, {
    "PreProc",
    "Include",
    "Define",
    "Macro",
    "PreCondit",
    "@keyword.directive",
    "@keyword.directive.define",
    "@keyword.import",
    "@function.macro",
    "@lsp.type.macro",
  }, { fg = palette.deep_red })

  set_groups(highlights, {
    "Type",
    "StorageClass",
    "Structure",
    "Typedef",
    "@type",
    "@type.builtin",
    "@type.definition",
    "@type.qualifier",
    "@constructor",
    "@module",
    "@namespace",
    "@lsp.type.class",
    "@lsp.type.enum",
    "@lsp.type.interface",
    "@lsp.type.namespace",
    "@lsp.type.struct",
    "@lsp.type.type",
    "@lsp.type.typeParameter",
  }, { fg = palette.orange })

  set_groups(highlights, {
    "String",
    "Character",
    "@string",
    "@character",
    "@lsp.type.string",
  }, { fg = palette.salmon })

  set_groups(highlights, {
    "Number",
    "Float",
    "Boolean",
    "Constant",
    "@number",
    "@number.float",
    "@float",
    "@boolean",
    "@constant",
    "@constant.builtin",
    "@constant.macro",
    "@lsp.type.number",
    "@lsp.type.enumMember",
  }, { fg = palette.orange })

  set_groups(highlights, {
    "Identifier",
    "@variable",
    "@variable.builtin",
    "@lsp.type.variable",
  }, { fg = palette.foreground })

  set_groups(highlights, {
    "@variable.parameter",
    "@variable.parameter.builtin",
    "@parameter",
    "@lsp.type.parameter",
  }, { fg = palette.soft })

  set_groups(highlights, {
    "@variable.member",
    "@property",
    "@field",
    "@lsp.type.property",
  }, { fg = palette.pale })

  set_groups(highlights, {
    "Special",
    "SpecialChar",
    "@string.escape",
    "@string.special",
    "@character.special",
  }, { fg = palette.coral })

  set_groups(highlights, {
    "Operator",
    "@operator",
    "@keyword.operator",
    "@lsp.type.operator",
  }, { fg = palette.soft })

  set_groups(highlights, {
    "Delimiter",
    "@punctuation",
    "@punctuation.bracket",
    "@punctuation.delimiter",
    "@punctuation.special",
    "@punctuation.bracket.cpp",
    "@punctuation.delimiter.cpp",
    "@punctuation.special.cpp",
    "@tag.delimiter",
  }, { fg = palette.punctuation })

  highlights["@custom.template_argument"] = { fg = palette.white }
  highlights["@custom.template_argument.cpp"] = { fg = palette.white }
  highlights["@custom.array_bracket"] = { fg = palette.array_bracket }
  highlights["@custom.array_bracket.cpp"] = { fg = palette.array_bracket }
  highlights.LspInlayHint = { fg = palette.inlay, bg = "NONE", italic = true }
end

return {
  transparent = false,
  colors = {
    base00 = "#1F1F1F",
    base01 = "#d12b2b",
    base02 = "#d12b2b",
    base03 = "#4b515b",
    base04 = "#ad2222",
    base05 = "#b9bec6",
    base06 = "#eceff2",
    base07 = "#332222",
    base08 = "#d12b2b",
    base09 = "#d12b2b",
    base0A = "#9e1a1a",
    base0B = "#eceff2",
    base0C = "#b9bec6",
    base0D = "#ad2222",
    base0E = "#c3c8d0",
    base0F = "#8f949c",
  },
  on_highlights = diversify_highlights,
}
