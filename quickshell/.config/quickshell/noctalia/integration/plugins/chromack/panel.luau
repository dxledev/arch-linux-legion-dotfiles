local Color = require("./lib/color.luau")
local Store = require("./lib/store.luau")

local state = nil
local activeTab = 1
local panelOpen = false
local pickerPending = false
local pickerMessage = ""
local pickerMessageIsError = false
local dirty = false
local lastPersist = 0
local saveName = "palette"
local storeError = ""
local lastThemeSignature = ""
local hoveredSwatchKey = nil

local tabNames = { "Color", "Shade", "Palette", "Theory" }

noctalia.setUpdateInterval(250)

local function ensureState()
  if state ~= nil then
    return
  end
  state, storeError = Store.load(Color)
end

local function flush()
  if state == nil then
    return
  end
  local ok, err = Store.persist(Color, state)
  dirty = not ok
  storeError = ok and "" or (err or "Could not save Chromack data.")
  if ok then
    lastPersist = noctalia.nowMs()
  end
end

local function markChanged(forceSave)
  dirty = true
  local now = noctalia.nowMs()
  if forceSave or lastPersist == 0 or now - lastPersist >= 250 then
    flush()
  end
end

local function view()
  ensureState()
  return Color.view(state)
end

local function themeSignature()
  return (noctalia.getColor("surface") or "") .. ":" .. (noctalia.getColor("outline") or "")
end

local function render()
  if not panelOpen then
    return
  end
  local current = view()
  local content

  local function sectionLabel(text, color)
    return ui.label({ text = text, fontWeight = "bold", fontSize = 13, color = color or "on_surface" })
  end

  local function smallText(text)
    return ui.label({ text = text, fontSize = 11, color = "on_surface_variant", maxLines = 2 })
  end

  local function valueSwatch(color, value, width, height, onClick, key)
    return ui.box({
      key = key,
      fill = color,
      width = width,
      height = height,
      radius = 5,
      border = hoveredSwatchKey == key and "primary" or "outline",
      borderWidth = hoveredSwatchKey == key and 2 or 1,
      tooltip = value,
      onClick = onClick,
      onHover = function(hoverState)
        if hoverState == "true" then
          if hoveredSwatchKey ~= key then
            hoveredSwatchKey = key
            render()
          end
        elseif hoveredSwatchKey == key then
          hoveredSwatchKey = nil
          render()
        end
      end,
    })
  end

  local function copyValue(value)
    if type(value) ~= "string" or value == "" then
      return
    end
    noctalia.copyToClipboard(value, "text/plain")
    local copiedColor = Color.parse(value)
    if copiedColor ~= nil then
      Color.pushRecent(state, copiedColor)
    end
    markChanged(true)
    noctalia.notify("Chromack", "Copied " .. value)
    render()
  end

  local function setColor(value, addRecent, preserveAlpha, generate)
    if not Color.setColor(state, value, addRecent, preserveAlpha) then
      state.status = "Invalid color. Use hex or rgba."
      render()
      return false
    end
    if generate then
      state.status = "Generated 24-base palette from " .. Color.toCss(state.active)
    else
      state.status = ""
    end
    markChanged(not generate)
    render()
    return true
  end

  local function setHuePlane(normX, normY)
    local saturation = math.max(0, math.min(1, tonumber(normX) or 0))
    local value = 1 - math.max(0, math.min(1, tonumber(normY) or 0))
    Color.setHsv(state, state.hue, saturation, value)
    state.status = ""
    markChanged(false)
    render()
  end

  local function setHueStrip(_, normY)
    local hue = math.floor(math.max(0, math.min(1, tonumber(normY) or 0)) * 359 + 0.5)
    Color.setHsv(state, hue, state.active.s, state.active.v)
    state.status = ""
    markChanged(false)
    render()
  end

  local function selectMaterial(index)
    if Color.selectMaterial(state, index) then
      state.status = ""
      markChanged(true)
      render()
    end
  end

  local function makeMaterialRows()
    local rows = {}
    for rowIndex = 0, 2 do
      local swatches = {}
      for column = 1, 16 do
        local index = rowIndex * 16 + column
        local entry = current.materials[index]
        table.insert(swatches, valueSwatch(entry.color, entry.css, nil, 20, function()
          selectMaterial(index)
        end, "material-" .. tostring(index)))
        swatches[#swatches].props.flexGrow = 1
      end
      table.insert(rows, ui.row({ gap = 2, align = "center" }, swatches))
    end
    return rows
  end

  local function makeRecentRow()
    local swatches = {}
    for index = 1, 16 do
      local entry = current.recent[index]
      local color = entry and entry.color or "surface_variant"
      local value = entry and entry.css or ""
      local swatch = valueSwatch(color, value, nil, 23, function()
        if entry ~= nil then
          setColor(entry.hex, false, false, false)
        end
      end, "recent-" .. tostring(index))
      swatch.props.flexGrow = 1
      swatch.props.visible = entry ~= nil
      table.insert(swatches, swatch)
    end
    return ui.row({ gap = 2, align = "center" }, swatches)
  end

  local function makeBaseInput()
    return ui.row({ gap = 8, align = "center" }, {
      sectionLabel("Base"),
      valueSwatch(current.color, current.css, 28, 28, function()
        copyValue(current.css)
      end, "base-color"),
      ui.input({
        key = "base-" .. current.hex,
        value = current.hex,
        placeholder = "#5f6b7b or rgba(95, 107, 123, 1)",
        flexGrow = 1,
        controlSize = "sm",
        onSubmit = function(value)
          setColor(value, false, true, false)
        end,
      }),
      ui.button({ text = "Generate", variant = "primary", controlSize = "sm", onClick = function()
        setColor(current.hex, false, true, true)
      end }),
    })
  end

  local function makePickerTab()
    local colorRow = ui.row({ gap = 8, align = "stretch", justify = "center" }, {
      ui.hsvPlane({
        key = "chromack-hsv-plane",
        hue = current.hue / 359,
        saturation = current.saturation,
        value = current.value,
        width = 400,
        height = 190,
        onChange = setHuePlane,
      }),
      ui.hueStrip({
        key = "chromack-hue-strip",
        hue = current.hue / 359,
        width = 22,
        height = 190,
        onChange = setHueStrip,
      }),
    })
    local opacity = ui.row({ gap = 8, align = "center" }, {
      sectionLabel("Opacity"),
      ui.slider({
        key = "chromack-opacity",
        min = 0,
        max = 255,
        step = 1,
        value = current.alpha,
        flexGrow = 1,
        controlSize = "sm",
        onChange = function(value)
          Color.setAlpha(state, tonumber(value) or current.alpha)
          markChanged(false)
          render()
        end,
      }),
      valueSwatch(current.color, current.css, 72, 28, function()
        copyValue(current.css)
      end, "picker-opacity"),
    })
    local values = ui.row({ gap = 6, align = "center" }, {
      sectionLabel("Hex"),
      ui.input({
        key = "hex-" .. current.hex,
        value = current.hex,
        flexGrow = 1,
        controlSize = "sm",
        onSubmit = function(value)
          setColor(value, false, false, false)
        end,
      }),
      ui.button({ glyph = "copy", tooltip = "Copy hex", variant = "ghost", controlSize = "sm", onClick = function()
        copyValue(current.hex)
      end }),
      sectionLabel("RGBA"),
      ui.input({
        key = "rgba-" .. current.rgba,
        value = current.rgba,
        flexGrow = 1,
        controlSize = "sm",
        onSubmit = function(value)
          setColor(value, false, false, false)
        end,
      }),
      ui.button({ glyph = "copy", tooltip = "Copy RGBA", variant = "ghost", controlSize = "sm", onClick = function()
        copyValue(current.rgba)
      end }),
    })
    local recentAndMaterials = makeMaterialRows()
    table.insert(recentAndMaterials, sectionLabel("Recent Colors"))
    table.insert(recentAndMaterials, makeRecentRow())
    return ui.column({ gap = 8, padding = 8, fill = "surface_variant", radius = 10 }, {
      colorRow,
      opacity,
      values,
      sectionLabel("Material Colors"),
      table.unpack(recentAndMaterials),
    })
  end

  local function makeShadesTab()
    local children = { makeBaseInput(), smallText("Shades add black, tints add white, and tones adjust saturation with gray.") }
    for _, section in ipairs(current.shades) do
      table.insert(children, sectionLabel(section.name))
      for rowIndex = 0, 1 do
        local swatches = {}
        for column = 1, 6 do
          local index = rowIndex * 6 + column
          local entry = section.colors[index]
          local swatch = valueSwatch(entry.color, entry.css, nil, 42, function()
            copyValue(entry.css)
          end, "shade-" .. section.name .. "-" .. tostring(index))
          swatch.props.flexGrow = 1
          table.insert(swatches, swatch)
        end
        table.insert(children, ui.row({ gap = 1 }, swatches))
      end
    end
    return ui.column({ gap = 7, padding = 8, fill = "surface_variant", radius = 10 }, children)
  end

  local function makePaletteTab()
    local saveRow = ui.row({ gap = 8, align = "center" }, {
      ui.input({
        key = "palette-name-" .. saveName,
        value = saveName,
        placeholder = "Palette name",
        flexGrow = 1,
        controlSize = "sm",
        onSubmit = function(value)
          saveName = value
        end,
        onChange = function(value)
          saveName = value
        end,
      }),
      ui.button({ text = "Export TOML", glyph = "device-floppy", variant = "primary", controlSize = "sm", onClick = function()
        local path, err = Store.exportPalette(Color, state, saveName)
        if path ~= nil then
          state.status = "Saved palette to " .. path
          noctalia.notify("Chromack", "Palette saved to " .. path)
        else
          state.status = err or "Could not save the palette."
          noctalia.notifyError("Chromack", state.status)
        end
        render()
      end }),
    })
    local rows = {
      makeBaseInput(),
      smallText(state.status ~= "" and state.status or ("Generated 24-base palette from " .. current.css)),
      saveRow,
    }
    for index, entry in ipairs(current.palette) do
      table.insert(rows, ui.row({ gap = 8, align = "center" }, {
        ui.label({ text = entry.name, width = 84, color = "on_surface" }),
        valueSwatch(entry.color, entry.css, 56, 24, function()
          copyValue(entry.css)
        end, "palette-" .. tostring(index)),
        ui.label({ text = entry.css, flexGrow = 1, fontSize = 12, color = "on_surface_variant" }),
        ui.button({ glyph = "copy", tooltip = "Copy " .. entry.name, variant = "ghost", controlSize = "sm", onClick = function()
          copyValue(entry.css)
        end }),
      }))
    end
    return ui.column({ gap = 6, padding = 8, fill = "surface_variant", radius = 10 }, rows)
  end

  local function makeTheoryTab()
    local children = { makeBaseInput(), smallText("Generate complementary values based on color theory.") }
    for _, scheme in ipairs(current.theory) do
      table.insert(children, sectionLabel(scheme.name))
      local swatches = {}
      for index, entry in ipairs(scheme.colors) do
        local swatch = valueSwatch(entry.color, entry.css, nil, 32, function()
          copyValue(entry.css)
        end, "theory-" .. scheme.name .. "-" .. tostring(index))
        swatch.props.flexGrow = 1
        table.insert(swatches, swatch)
      end
      table.insert(children, ui.row({ gap = 1 }, swatches))
    end
    table.insert(children, sectionLabel("Color Wheel"))
    table.insert(children, ui.row({ justify = "center" }, {
      ui.colorWheel({
        key = "chromack-theory-wheel",
        colors = current.wheelColors,
        width = 360,
        height = 360,
        onSelect = function(indexText)
          local index = tonumber(indexText)
          local entry = index and current.wheel[index]
          if entry ~= nil then
            copyValue(entry.css)
          end
        end,
      }),
    }))
    return ui.column({ gap = 7, padding = 8, fill = "surface_variant", radius = 10 }, children)
  end

  if activeTab == 1 then
    content = makePickerTab()
  elseif activeTab == 2 then
    content = makeShadesTab()
  elseif activeTab == 3 then
    content = makePaletteTab()
  else
    content = makeTheoryTab()
  end

  local tabs = {}
  for index, name in ipairs(tabNames) do
    local selected = activeTab == index
    local tabButton = {
      key = "chromack-tab-" .. tostring(index),
      variant = selected and "primary" or "outline",
      controlSize = "sm",
      flexGrow = 1,
      selected = selected,
      onClick = function()
        activeTab = index
        render()
      end,
    }
    tabButton.text = name
    table.insert(tabs, ui.button(tabButton))
  end

  local subtitle = current.css .. (state.selected > 0 and (" · Material " .. string.format("%02d", state.selected)) or "")
  local footer = {}
  if pickerMessage ~= "" then
    table.insert(footer, ui.label({
      text = pickerMessage,
      color = pickerMessageIsError and "error" or "on_surface_variant",
      fontSize = 11,
      maxLines = 2,
    }))
  end
  if storeError ~= "" then
    table.insert(footer, ui.label({ text = storeError, color = "error", fontSize = 11, maxLines = 2 }))
  end
  if pickerPending then
    table.insert(footer, ui.label({ text = "Screen picking is in progress.", color = "on_surface_variant", fontSize = 11 }))
  end
  panel.render(ui.column({ flexGrow = 1, padding = 10 }, {
    ui.column({ fill = "surface", border = "outline", borderWidth = 1, radius = 12, padding = 12, gap = 8, flexGrow = 1 }, {
      ui.row({ gap = 8, align = "center" }, {
        ui.column({ gap = 1, flexGrow = 1 }, {
          ui.label({ text = "Chromack", fontWeight = "bold", fontSize = 18, color = "on_surface" }),
          ui.label({ text = subtitle, fontSize = 11, color = "on_surface_variant" }),
        }),
        ui.button({ glyph = "color-picker", tooltip = "Pick from screen", variant = "outline", controlSize = "sm", width = 32, height = 32, enabled = not pickerPending, onClick = function()
          if pickerPending then
            return
          end
          local pluginDirectory = noctalia.pluginDir()
          if type(pluginDirectory) ~= "string" or pluginDirectory == "" then
            pickerMessage = "Could not locate the screen picker helper."
            pickerMessageIsError = true
            render()
            return
          end
          pickerPending = true
          pickerMessage = ""
          pickerMessageIsError = false
          render()
          if not noctalia.runAsync({ pluginDirectory .. "/pick-screen-color" }) then
            pickerPending = false
            pickerMessage = "Could not start the screen picker helper."
            pickerMessageIsError = true
            render()
            return
          end
          panel.close()
        end }),
        ui.button({ glyph = "x", tooltip = "Close Chromack", variant = "destructive", controlSize = "sm", width = 32, height = 32, onClick = function()
          panel.close()
        end }),
      }),
      ui.row({ gap = 4, align = "center" }, tabs),
      ui.scroll({ flexGrow = 1, fill = "surface_variant", border = "outline", borderWidth = 1, radius = 10, padding = 8, gap = 8 }, {
        ui.column({ gap = 8 }, { content }),
      }),
      table.unpack(footer),
    }),
  }))
end

function update()
  if panelOpen then
    local signature = themeSignature()
    if signature ~= lastThemeSignature then
      lastThemeSignature = signature
      render()
    end
  end
  if dirty and noctalia.nowMs() - lastPersist >= 250 then
    flush()
  end
end

function onOpen(context)
  state, storeError = Store.load(Color)
  lastPersist = noctalia.nowMs()
  lastThemeSignature = themeSignature()
  panelOpen = true
  if context == nil or context == "" then
    pickerMessage = ""
    pickerMessageIsError = false
  elseif context == "picker-cancelled" then
    pickerPending = false
    pickerMessage = "Screen pick cancelled."
    pickerMessageIsError = false
  elseif context == "picker-error:not-found" then
    pickerPending = false
    pickerMessage = "hyprpicker is not available."
    pickerMessageIsError = true
  elseif context == "picker-error:failed" then
    pickerPending = false
    pickerMessage = "Screen picker failed."
    pickerMessageIsError = true
  elseif context == "picker-error:invalid-result" then
    pickerPending = false
    pickerMessage = "Screen picker returned an invalid color."
    pickerMessageIsError = true
  elseif type(context) == "string" and string.match(context, "^#%x%x%x%x%x%x$") ~= nil then
    if Color.setColor(state, context, true, false) then
      pickerPending = false
      pickerMessage = ""
      pickerMessageIsError = false
      noctalia.copyToClipboard(Color.toHexInput(state.active), "text/plain")
      markChanged(true)
    else
      pickerPending = false
      pickerMessage = "Screen picker returned an invalid color."
      pickerMessageIsError = true
    end
  elseif type(context) == "string" and string.sub(context, 1, 7) == "picker-" then
    pickerPending = false
    pickerMessage = "Screen picker failed."
    pickerMessageIsError = true
  end
  render()
end

function onClose()
  panelOpen = false
  flush()
end

function onExit()
  panelOpen = false
  flush()
end
