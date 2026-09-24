local M = {}

local materialValues = {
  "#f44336", "#e91e63", "#9c27b0", "#673ab7", "#3f51b5", "#2196f3", "#03a9f4", "#00bcd4",
  "#009688", "#4caf50", "#8bc34a", "#cddc39", "#ffeb3b", "#ffc107", "#ff9800", "#ff5722",
  "#ef5350", "#ec407a", "#ab47bc", "#7e57c2", "#5c6bc0", "#42a5f5", "#29b6f6", "#26c6da",
  "#26a69a", "#66bb6a", "#9ccc65", "#d4e157", "#ffee58", "#ffca28", "#ffa726", "#ff7043",
  "#d32f2f", "#c2185b", "#7b1fa2", "#512da8", "#303f9f", "#1976d2", "#0288d1", "#0097a7",
  "#00796b", "#388e3c", "#689f38", "#afb42b", "#f57f17", "#ffffff", "#9e9e9e", "#000000",
}

local namedColors = {
  black = { 0, 0, 0, 255 }, white = { 255, 255, 255, 255 }, red = { 255, 0, 0, 255 },
  green = { 0, 128, 0, 255 }, blue = { 0, 0, 255, 255 }, yellow = { 255, 255, 0, 255 },
  orange = { 255, 165, 0, 255 }, purple = { 128, 0, 128, 255 }, pink = { 255, 192, 203, 255 },
  gray = { 128, 128, 128, 255 }, grey = { 128, 128, 128, 255 }, transparent = { 0, 0, 0, 0 },
}

local function toFloat32(value)
  return string.unpack("f", string.pack("f", value))
end

local function clamp(value, low, high)
  return math.max(low, math.min(high, value))
end

local function round(value)
  return math.floor(value + 0.5)
end

local function byte(value)
  return clamp(round(value), 0, 255)
end

local function makeColor(red, green, blue, alpha)
  local color = { r = byte(red), g = byte(green), b = byte(blue), a = byte(alpha or 255) }
  local maximum = math.max(color.r, color.g, color.b) / 255
  local minimum = math.min(color.r, color.g, color.b) / 255
  local delta = maximum - minimum
  local hue = -1
  if delta > 0 then
    local r = color.r / 255
    local g = color.g / 255
    local b = color.b / 255
    if maximum == r then
      hue = 60 * (((g - b) / delta) % 6)
    elseif maximum == g then
      hue = 60 * (((b - r) / delta) + 2)
    else
      hue = 60 * (((r - g) / delta) + 4)
    end
    hue = hue % 360
  end
  color.h = hue < 0 and -1 or toFloat32(hue)
  color.s = toFloat32(maximum == 0 and 0 or delta / maximum)
  color.v = toFloat32(maximum)
  return color
end

local function hexByte(value)
  return tonumber(value, 16)
end

local function parseHex(value)
  local digits = string.sub(value, 2)
  if #digits == 3 then
    return makeColor(hexByte(string.sub(digits, 1, 1)) * 17, hexByte(string.sub(digits, 2, 2)) * 17, hexByte(string.sub(digits, 3, 3)) * 17, 255), false
  end
  if #digits == 4 then
    return makeColor(hexByte(string.sub(digits, 2, 2)) * 17, hexByte(string.sub(digits, 3, 3)) * 17, hexByte(string.sub(digits, 4, 4)) * 17, hexByte(string.sub(digits, 1, 1)) * 17), true
  end
  if #digits == 6 then
    return makeColor(hexByte(string.sub(digits, 1, 2)), hexByte(string.sub(digits, 3, 4)), hexByte(string.sub(digits, 5, 6)), 255), false
  end
  if #digits == 8 then
    return makeColor(hexByte(string.sub(digits, 3, 4)), hexByte(string.sub(digits, 5, 6)), hexByte(string.sub(digits, 7, 8)), hexByte(string.sub(digits, 1, 2))), true
  end
  return nil
end

local function parseFunctional(value)
  local red, green, blue, alpha = string.match(value, "^rgba%s*%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*([%d%.]+)%s*%)$")
  if red == nil then
    red, green, blue = string.match(value, "^rgba?%s*%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)$")
  end
  if red == nil then
    return nil
  end
  local opacity = alpha and tonumber(alpha) or 1
  if opacity == nil then
    return nil
  end
  local color = makeColor(tonumber(red), tonumber(green), tonumber(blue), clamp(opacity, 0, 1) * 255)
  return color, alpha ~= nil
end

function M.parse(value)
  if type(value) ~= "string" then
    return nil, false
  end
  local trimmed = string.match(value, "^%s*(.-)%s*$")
  local hex = string.match(trimmed, "^#([%x]+)$")
  if hex ~= nil then
    return parseHex("#" .. hex)
  end
  local functional, explicit = parseFunctional(string.lower(trimmed))
  if functional ~= nil then
    return functional, explicit
  end
  local named = namedColors[string.lower(trimmed)]
  if named ~= nil then
    return makeColor(named[1], named[2], named[3], named[4]), true
  end
  return nil, false
end

function M.toCss(color)
  if color.a >= 255 then
    return string.format("#%02x%02x%02x", color.r, color.g, color.b)
  end
  local alpha = string.format("%.2f", color.a / 255)
  alpha = string.gsub(alpha, "0+$", "")
  alpha = string.gsub(alpha, "%.$", "")
  return string.format("rgba(%d, %d, %d, %s)", color.r, color.g, color.b, alpha)
end

function M.toHexInput(color)
  if color.a >= 255 then
    return string.format("#%02x%02x%02x", color.r, color.g, color.b)
  end
  return string.format("#%02x%02x%02x%02x", color.a, color.r, color.g, color.b)
end

function M.toHexRgba(color)
  return string.format("#%02x%02x%02x%02x", color.r, color.g, color.b, color.a)
end

function M.toPaletteFileColor(color)
  if color.a >= 255 then
    return string.format("#%02x%02x%02x", color.r, color.g, color.b)
  end
  return M.toHexRgba(color)
end

local function fromHsvFloat(hue, saturation, value, alpha)
  hue = toFloat32(hue)
  saturation = toFloat32(saturation)
  value = toFloat32(value)
  alpha = toFloat32(alpha or 255)
  local normalized = (hue % 360) / 60
  local chroma = value * saturation
  local cross = chroma * (1 - math.abs((normalized % 2) - 1))
  local red, green, blue
  if normalized < 1 then
    red, green, blue = chroma, cross, 0
  elseif normalized < 2 then
    red, green, blue = cross, chroma, 0
  elseif normalized < 3 then
    red, green, blue = 0, chroma, cross
  elseif normalized < 4 then
    red, green, blue = 0, cross, chroma
  elseif normalized < 5 then
    red, green, blue = cross, 0, chroma
  else
    red, green, blue = chroma, 0, cross
  end
  local offset = value - chroma
  return makeColor((red + offset) * 255, (green + offset) * 255, (blue + offset) * 255, alpha)
end

local function fromHsv(hue, saturation, value, alpha)
  local sat = byte(clamp(saturation, 0, 1) * 255) / 255
  local val = byte(clamp(value, 0, 1) * 255) / 255
  return fromHsvFloat(clamp(round(hue), 0, 359), sat, val, alpha)
end

local function blend(left, right, amount)
  local t = clamp(amount, 0, 1)
  local inverse = 1 - t
  return makeColor(
    left.r * inverse + right.r * t,
    left.g * inverse + right.g * t,
    left.b * inverse + right.b * t,
    left.a * inverse + right.a * t
  )
end

local function wrapHue(hue)
  return hue % 360
end

local function colorAtHue(base, hue, saturationScale, valueScale)
  return fromHsvFloat(
    wrapHue(hue),
    clamp(base.s * (saturationScale or 1), 0, 1),
    clamp(base.v * (valueScale or 1), 0, 1),
    base.a
  )
end

local function terminal24(base)
  local hue = base.h < 0 and 0 or base.h
  local saturation = base.s
  local value = base.v
  local neutralSaturation = clamp(saturation * 0.12, 0, 0.14)
  local normalSaturation = clamp(0.36 + saturation * 0.42, 0.42, 0.82)
  local normalValue = clamp(0.40 + value * 0.25, 0.38, 0.72)
  local brightSaturation = clamp(normalSaturation + 0.08, 0.48, 0.90)
  local brightValue = clamp(normalValue + 0.22, 0.64, 0.96)
  local normalBlack = fromHsvFloat(hue, neutralSaturation, clamp(value * 0.18, 0.06, 0.20), 255)
  local normalWhite = fromHsvFloat(hue, clamp(saturation * 0.06, 0, 0.08), clamp(value * 0.75 + 0.16, 0.72, 0.90), 255)
  local brightBlack = fromHsvFloat(hue, neutralSaturation, clamp(value * 0.34 + 0.06, 0.20, 0.40), 255)
  local brightWhite = fromHsvFloat(hue, clamp(saturation * 0.04, 0, 0.06), clamp(value * 0.92 + 0.18, 0.92, 1), 255)
  local colors = { normalBlack }
  for _, offset in ipairs({ 0, 120, 60, 240, 300, 180 }) do
    table.insert(colors, fromHsvFloat(hue + offset, normalSaturation, normalValue, 255))
  end
  table.insert(colors, normalWhite)
  table.insert(colors, brightBlack)
  for _, offset in ipairs({ 0, 120, 60, 240, 300, 180 }) do
    table.insert(colors, fromHsvFloat(hue + offset, brightSaturation, brightValue, 255))
  end
  table.insert(colors, brightWhite)
  local dimAnchor = blend(normalBlack, base, 0.10)
  for i = 1, 8 do
    local dim = blend(colors[i], dimAnchor, 0.46)
    table.insert(colors, fromHsvFloat(dim.h < 0 and hue or dim.h, clamp(dim.s * 0.72, 0, 1), clamp(dim.v * 0.80, 0, 1), 255))
  end
  return colors
end

local function relativeLuminance(color)
  local function linearize(channel)
    local normalized = channel / 255
    if normalized <= 0.03928 then
      return normalized / 12.92
    end
    return ((normalized + 0.055) / 1.055) ^ 2.4
  end
  return 0.2126 * linearize(color.r) + 0.7152 * linearize(color.g) + 0.0722 * linearize(color.b)
end

function M.palette(base)
  local terminal = terminal24(base)
  local background = blend(terminal[1], base, 0.20)
  local foreground
  if relativeLuminance(background) > 0.42 then
    foreground = blend(terminal[1], base, 0.18)
  else
    foreground = blend(terminal[16], base, 0.08)
  end
  local result = {
    { name = "Foreground", color = foreground },
    { name = "Background", color = background },
  }
  for i, color in ipairs(terminal) do
    table.insert(result, { name = string.format("Color %02d", i - 1), color = color })
  end
  return result
end

local function shadeScale(base, steps, mode)
  local colors = {}
  local divisor = math.max(1, steps - 1)
  for index = 0, steps - 1 do
    local amount = index / divisor
    if mode == "shade" then
      table.insert(colors, blend(makeColor(0, 0, 0, base.a), base, amount))
    elseif mode == "tint" then
      table.insert(colors, blend(base, makeColor(255, 255, 255, base.a), amount))
    else
      local minimum = clamp(base.s * 0.12, 0, 0.28)
      local maximum = clamp(base.s + 0.28, 0, 1)
      local saturation = minimum + (maximum - minimum) * amount
      local value = clamp(base.v * 0.92 + 0.08 * amount, 0, 1)
      table.insert(colors, fromHsvFloat(base.h < 0 and 0 or base.h, saturation, value, base.a))
    end
  end
  return colors
end

local function theory(base)
  local hue = wrapHue(base.h < 0 and 0 or base.h)
  local schemes = {
    { name = "Complementary Color", hues = { hue, hue + 180 } },
    { name = "Analogous Color", hues = { hue - 30, hue, hue + 30 } },
    { name = "Split Complementary Color", hues = { hue, hue + 150, hue + 210 } },
    { name = "Triadic Color", hues = { hue, hue + 120, hue + 240 } },
    { name = "Tetradic Color", hues = { hue, hue + 90, hue + 180, hue + 270 } },
  }
  for _, scheme in ipairs(schemes) do
    scheme.colors = {}
    for _, schemeHue in ipairs(scheme.hues) do
      table.insert(scheme.colors, colorAtHue(base, schemeHue))
    end
    scheme.hues = nil
  end
  local values = { 0.40, 0.52, 0.64, 0.76, 0.84, 0.92, 1.0 }
  local saturations = { 1.10, 1.06, 1.02, 0.98, 0.90, 0.82, 0.74 }
  local monochromatic = { name = "Monochromatic Color", colors = {} }
  for i = 1, #values do
    table.insert(monochromatic.colors, fromHsvFloat(
      base.h < 0 and 0 or base.h,
      clamp(base.s * saturations[i], 0, 1),
      clamp(base.v * values[i], 0, 1),
      base.a
    ))
  end
  table.insert(schemes, monochromatic)
  return schemes
end

local function colorList(colors)
  local result = {}
  for _, color in ipairs(colors) do
    table.insert(result, {
      color = M.toHexRgba(color),
      css = M.toCss(color),
      hex = M.toHexInput(color),
    })
  end
  return result
end

function M.initial()
  local materials = {}
  for index, value in ipairs(materialValues) do
    materials[index] = M.parse(value)
  end
  return {
    selected = 1,
    active = M.parse(materialValues[1]),
    materials = materials,
    recent = {},
    hue = 0,
    status = "",
  }
end

function M.materialsDefault()
  local values = {}
  for index, value in ipairs(materialValues) do
    values[index] = value
  end
  return values
end

function M.materialKey(index)
  return string.format("--color-material-%02d", index)
end

function M.setColor(state, value, addRecent, preserveAlpha)
  local color, explicitAlpha = M.parse(value)
  if color == nil then
    return false
  end
  if preserveAlpha and not explicitAlpha then
    color.a = state.active.a
    color = makeColor(color.r, color.g, color.b, color.a)
  end
  state.active = color
  if color.h >= 0 then
    state.hue = round(color.h)
  end
  state.materials[state.selected] = color
  if addRecent then
    M.pushRecent(state, color)
  end
  return true
end

function M.setHsv(state, hue, saturation, value)
  state.hue = clamp(round(hue), 0, 359)
  local color = fromHsv(state.hue, saturation, value, state.active.a)
  state.active = color
  state.materials[state.selected] = color
end

function M.setAlpha(state, alpha)
  state.active = makeColor(state.active.r, state.active.g, state.active.b, clamp(round(alpha), 0, 255))
  state.materials[state.selected] = state.active
end

function M.selectMaterial(state, index)
  if index < 1 or index > #state.materials then
    return false
  end
  state.selected = index
  state.active = state.materials[index]
  state.hue = state.active.h < 0 and 0 or round(state.active.h)
  return true
end

function M.pushRecent(state, color)
  local key = string.format("%d:%d:%d:%d", color.r, color.g, color.b, color.a)
  local nextRecent = { color }
  for _, existing in ipairs(state.recent) do
    local existingKey = string.format("%d:%d:%d:%d", existing.r, existing.g, existing.b, existing.a)
    if existingKey ~= key and #nextRecent < 16 then
      table.insert(nextRecent, existing)
    end
  end
  state.recent = nextRecent
end

function M.view(state)
  local active = state.active
  local palette = M.palette(active)
  local shadeNames = { "Shades", "Tints", "Tones" }
  local shadeModes = { "shade", "tint", "tone" }
  local shades = {}
  for index, mode in ipairs(shadeModes) do
    local colors = shadeScale(active, 12, mode)
    local firstHex = string.format("#%02x%02x%02x", colors[1].r, colors[1].g, colors[1].b)
    local lastHex = string.format("#%02x%02x%02x", colors[#colors].r, colors[#colors].g, colors[#colors].b)
    local description
    if mode == "shade" then
      description = string.format("%s is darkest while %s is closest to base.", firstHex, lastHex)
    elseif mode == "tint" then
      description = string.format("%s starts at base and %s is lightest.", firstHex, lastHex)
    else
      description = string.format("%s is least saturated while %s is most saturated.", firstHex, lastHex)
    end
    table.insert(shades, {
      name = shadeNames[index],
      description = description,
      colors = colorList(colors),
    })
  end
  local schemes = theory(active)
  local theoryRows = {}
  for _, scheme in ipairs(schemes) do
    table.insert(theoryRows, { name = scheme.name, colors = colorList(scheme.colors) })
  end
  local wheel = {}
  local baseHue = wrapHue(active.h < 0 and 0 or active.h)
  for index = 0, 23 do
    local color = colorAtHue(active, baseHue + index * 15)
    table.insert(wheel, { color = color, css = M.toCss(color), hex = M.toHexInput(color) })
  end
  local materials = {}
  for index, color in ipairs(state.materials) do
    table.insert(materials, {
      color = M.toHexRgba(color),
      css = M.toCss(color),
      hex = M.toHexInput(color),
      index = index,
    })
  end
  local recent = colorList(state.recent)
  local paletteRows = {}
  for _, row in ipairs(palette) do
    table.insert(paletteRows, {
      name = row.name,
      color = M.toHexRgba(row.color),
      css = M.toCss(row.color),
      hex = M.toPaletteFileColor(row.color),
    })
  end
  local wheelHex = {}
  for _, entry in ipairs(wheel) do
    table.insert(wheelHex, M.toHexRgba(entry.color))
  end
  return {
    color = M.toHexRgba(active),
    hex = M.toHexInput(active),
    rgba = string.format("rgba(%d, %d, %d, %s)", active.r, active.g, active.b, (string.gsub(string.gsub(string.format("%.2f", active.a / 255), "0+$", ""), "%.$", ""))),
    css = M.toCss(active),
    hue = state.hue,
    saturation = active.s,
    value = active.v,
    alpha = active.a,
    materials = materials,
    selected = state.selected,
    recent = recent,
    palette = paletteRows,
    shades = shades,
    theory = theoryRows,
    wheel = wheel,
    wheelColors = wheelHex,
    status = state.status,
  }
end

function M.paletteCssRows(base)
  return M.palette(base)
end

function M.materialDefaults()
  return materialValues
end

return M
