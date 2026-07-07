return {
  {
    "shaunsingh/nord.nvim",
    name = "nord",
    lazy = true,
    priority = 1000,

    init = function()
      -- Nord options
      -- These must exist before :colorscheme nord runs.
      vim.g.nord_contrast = true
      vim.g.nord_borders = true
      vim.g.nord_disable_background = true
      vim.g.nord_italic = true

      local palette = {
        white = "#D8DEE9",
        white_bright = "#E5E9F0",
        white_brightest = "#ECEFF4",
        red = "#bf616a",
        orange = "#D08770",
        purple = "#b48ead",
        gray = "#5f6775",
      }

      local function nord_highlights()
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

        -- Parentheses / brackets
        vim.api.nvim_set_hl(0, "@punctuation.bracket", {
          fg = palette.white, -- Nord white / Snow Storm
        })

        vim.api.nvim_set_hl(0, "@punctuation.bracket.cpp", {
          fg = palette.white,
        })

        -- Namespace, like std in std::string
        vim.api.nvim_set_hl(0, "@module", {
          fg = palette.white,
        })

        vim.api.nvim_set_hl(0, "@module.cpp", {
          fg = palette.white,
        })

        vim.api.nvim_set_hl(0, "@namespace", {
          fg = palette.white,
        })

        vim.api.nvim_set_hl(0, "@namespace.cpp", {
          fg = palette.white,
        })

        vim.api.nvim_set_hl(0, "@lsp.type.namespace.cpp", {
          fg = palette.white,
        })

        -- return keyword
        vim.api.nvim_set_hl(0, "@keyword.return", {
          fg = palette.orange,
          italic = true,
        })

        vim.api.nvim_set_hl(0, "@keyword.return.cpp", {
          fg = palette.orange,
          italic = true,
        })

        -- break / continue keywords
        vim.api.nvim_set_hl(0, "@keyword.repeat", {
          fg = palette.red,
          italic = true,
        })

        vim.api.nvim_set_hl(0, "@keyword.repeat.cpp", {
          fg = palette.red,
          italic = true,
        })

        -- Template arguments inside <>, like Pet in std::optional<Pet>
        vim.api.nvim_set_hl(0, "@custom.template_argument", {
          fg = palette.purple,
        })

        vim.api.nvim_set_hl(0, "@custom.template_argument.cpp", {
          fg = palette.purple,
        })

      end

      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "nord",
        callback = function()
          vim.schedule(nord_highlights)
        end,
      })
    end,
  },
}
