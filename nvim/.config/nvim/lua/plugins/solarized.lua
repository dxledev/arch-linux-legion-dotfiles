local solarized_config = {
  inlay_hint_shade = 3,
}

return {
  {
    "maxmx03/solarized.nvim",
    opts = {
      palette = "solarized",
      variant = "autumn",
      styles = {
        constants = { bold = true },
      },
      on_highlights = function(colors, color)
        return {
          LspInlayHint = {
            fg = color.shade(colors.base01, solarized_config.inlay_hint_shade),
          },
        }
      end,
    },
  },
}
