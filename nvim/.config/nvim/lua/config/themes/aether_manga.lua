local palette = {
  background = "#020202",
  black = "#1c1c1c",
  foreground = "#d1cfcf",
  muted = "#9a9494",
  punctuation = "#6f6b6b",
  inlay = "#403d3d",
  red = "#b59696",
  green = "#a8b596",
  yellow = "#b5ae96",
  blue = "#96a6b5",
  magenta = "#ad96b5",
  cyan = "#96b5b2",
  white = "#c3c3c3",
  bright_red = "#e0c7c7",
  bright_green = "#d3e0c7",
  bright_yellow = "#e0d9c7",
  bright_blue = "#c7d4e0",
  bright_magenta = "#d8c7e0",
  bright_cyan = "#c7e0dc",
  bright_white = "#e6e4e4",
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
  }, { fg = palette.bright_blue })

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
    "@keyword.return",
    "@keyword.storage",
    "@lsp.type.keyword",
    "@lsp.type.modifier",
  }, { fg = palette.red })

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
  }, { fg = palette.magenta })

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
    "@lsp.type.class",
    "@lsp.type.enum",
    "@lsp.type.interface",
    "@lsp.type.struct",
    "@lsp.type.type",
    "@lsp.type.typeParameter",
  }, { fg = palette.yellow })

  set_groups(highlights, {
    "@module",
    "@namespace",
    "@lsp.type.namespace",
  }, { fg = palette.bright_magenta })

  set_groups(highlights, {
    "String",
    "Character",
    "@string",
    "@character",
    "@lsp.type.string",
  }, { fg = palette.green })

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
  }, { fg = palette.bright_yellow })

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
  }, { fg = palette.cyan })

  set_groups(highlights, {
    "@variable.member",
    "@property",
    "@field",
    "@lsp.type.property",
  }, { fg = palette.bright_cyan })

  set_groups(highlights, {
    "Special",
    "SpecialChar",
    "@string.escape",
    "@string.special",
    "@character.special",
  }, { fg = palette.bright_green })

  set_groups(highlights, {
    "Operator",
    "@operator",
    "@keyword.operator",
    "@lsp.type.operator",
  }, { fg = palette.blue })

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
    "@custom.array_bracket",
    "@custom.array_bracket.cpp",
  }, { fg = palette.punctuation })

  highlights["@custom.template_argument"] = { fg = palette.bright_white }
  highlights["@custom.template_argument.cpp"] = { fg = palette.bright_white }
  highlights.LspInlayHint = { fg = palette.inlay, bg = "NONE", italic = true }
end

return {
  colors = {
    base00 = palette.background,
    base01 = palette.black,
    base02 = palette.black,
    base03 = palette.muted,
    base04 = palette.white,
    base05 = palette.foreground,
    base06 = palette.bright_white,
    base07 = palette.white,
    base08 = palette.red,
    base09 = palette.bright_red,
    base0A = palette.yellow,
    base0B = palette.green,
    base0C = palette.cyan,
    base0D = palette.blue,
    base0E = palette.magenta,
    base0F = palette.bright_magenta,
  },
  on_highlights = diversify_highlights,
}
