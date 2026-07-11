return {
  {
    "bjarneo/firesky.nvim",
    name = "firesky",
    lazy = true,
    priority = 1000,

    opts = {
      transparent = false,
      plugins = {
        snacks = false,
      },
    },

    init = function()
      local palette = {
        fg = "#f5f0e8",
        muted = "#426666",
        punctuation = "#7d7569",
        orange = "#ff7540",
        amber = "#ffad52",
        gold = "#ffc275",
        teal = "#40c4c0",
        cyan = "#52d9dd",
        aqua = "#70f0ed",
        seafoam = "#7bb8a7",
      }

      local function set_hl(group, opts)
        vim.api.nvim_set_hl(0, group, opts)
      end

      local function set_hls(groups, opts)
        for _, group in ipairs(groups) do
          set_hl(group, opts)
        end
      end

      local function firesky_highlights()
        if vim.g.colors_name ~= "firesky" then
          return
        end

        set_hls({
          "Comment",
          "@comment",
          "@comment.documentation",
          "@lsp.type.comment",
        }, {
          fg = palette.muted,
          italic = true,
        })

        set_hls({
          "Function",
          "@function",
          "@function.call",
          "@function.method",
          "@function.method.call",
          "@method",
          "@method.call",
          "@lsp.type.function",
          "@lsp.type.method",
        }, {
          fg = palette.cyan,
        })

        set_hls({
          "@function.builtin",
          "@function.macro",
          "@lsp.type.macro",
          "Macro",
        }, {
          fg = palette.aqua,
          bold = true,
        })

        set_hls({
          "Keyword",
          "Statement",
          "Conditional",
          "Repeat",
          "Exception",
          "PreProc",
          "Include",
          "Define",
          "PreCondit",
          "@keyword",
          "@keyword.function",
          "@keyword.import",
          "@keyword.conditional",
          "@keyword.repeat",
          "@keyword.exception",
          "@keyword.return",
          "@keyword.directive",
          "@keyword.directive.define",
          "@conditional",
          "@repeat",
          "@exception",
          "@include",
          "@define",
          "@lsp.type.keyword",
          "@lsp.type.modifier",
        }, {
          fg = palette.orange,
          italic = true,
        })

        set_hls({
          "Type",
          "Structure",
          "Typedef",
          "@type",
          "@type.builtin",
          "@type.definition",
          "@constructor",
          "@namespace",
          "@module",
          "@lsp.type.class",
          "@lsp.type.enum",
          "@lsp.type.interface",
          "@lsp.type.namespace",
          "@lsp.type.struct",
          "@lsp.type.type",
          "@lsp.type.typeParameter",
        }, {
          fg = palette.amber,
        })

        set_hls({
          "@custom.template_argument",
          "@custom.template_argument.cpp",
        }, {
          fg = palette.gold,
        })

        set_hls({
          "String",
          "Character",
          "@string",
          "@character",
          "@lsp.type.string",
        }, {
          fg = palette.seafoam,
        })

        set_hls({
          "Special",
          "SpecialChar",
          "@string.escape",
          "@string.special",
          "@character.special",
        }, {
          fg = palette.gold,
        })

        set_hls({
          "Number",
          "Float",
          "Boolean",
          "Constant",
          "@number",
          "@float",
          "@boolean",
          "@constant",
          "@constant.builtin",
          "@constant.macro",
          "@lsp.type.number",
          "@lsp.type.enumMember",
        }, {
          fg = palette.gold,
        })

        set_hls({
          "Identifier",
          "@variable",
          "@variable.cpp",
          "@parameter",
          "@parameter.cpp",
          "@variable.parameter",
          "@variable.parameter.cpp",
          "@lsp.type.variable",
          "@lsp.type.parameter",
        }, {
          fg = palette.fg,
        })

        set_hls({
          "@variable.member",
          "@property",
          "@field",
          "@lsp.type.property",
        }, {
          fg = palette.seafoam,
        })

        set_hls({
          "Operator",
          "@operator",
          "@keyword.operator",
          "@lsp.type.operator",
        }, {
          fg = palette.teal,
        })

        set_hls({
          "Delimiter",
          "@punctuation",
          "@punctuation.bracket",
          "@punctuation.delimiter",
          "@punctuation.special",
          "@punctuation.bracket.cpp",
          "@punctuation.delimiter.cpp",
          "@punctuation.special.cpp",
        }, {
          fg = palette.punctuation,
        })

        set_hl("LspInlayHint", {
          fg = palette.muted,
          bg = "NONE",
          italic = true,
        })

        set_hl("LspSignatureActiveParameter", {
          fg = palette.gold,
          bg = "NONE",
          bold = true,
        })
      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "firesky",
        callback = function()
          vim.schedule(firesky_highlights)
        end,
      })

      vim.schedule(firesky_highlights)
    end,

    config = function(_, opts)
      require("firesky").setup(opts)
    end,
  },
}
