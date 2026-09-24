function update()
  local label = noctalia.getConfig("label") or "Chromack"
  local glyph = noctalia.getConfig("glyph") or "color-swatch"
  barWidget.render(ui.row({ gap = 6, align = "center" }, {
    ui.glyph({ name = glyph, size = 14, color = "primary" }),
    ui.label({ text = label, color = "on_surface", fontWeight = "medium" }),
  }))
end
