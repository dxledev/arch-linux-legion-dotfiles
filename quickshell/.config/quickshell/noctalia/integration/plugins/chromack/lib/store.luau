local M = {}

local function readJson(path)
  local raw = noctalia.readFile(path)
  if type(raw) ~= "string" then
    return nil
  end
  local ok, result = pcall(noctalia.json.decode, raw)
  if ok and type(result) == "table" then
    return result
  end
  return nil
end

local function writeFile(path, content)
  local ok, err = noctalia.writeFile(path, content)
  if not ok then
    return false, err or ("Could not save " .. path)
  end
  return true
end

function M.load(Color)
  local directory, err = noctalia.pluginDataDir()
  if type(directory) ~= "string" then
    return Color.initial(), err or "Noctalia plugin data directory is unavailable."
  end
  local state = Color.initial()
  local stored = readJson(directory .. "/state.json")
  if stored ~= nil then
    if type(stored.selected) == "number" then
      state.selected = math.max(1, math.min(48, math.floor(stored.selected)))
    end
    if type(stored.hue) == "number" then
      state.hue = math.max(0, math.min(359, math.floor(stored.hue + 0.5)))
    end
  end
  local materials = readJson(directory .. "/materials.json")
  if materials ~= nil then
    for index = 1, 48 do
      local value = Color.parse(materials[index])
      if value ~= nil then
        state.materials[index] = value
      end
    end
  elseif stored ~= nil and type(stored.materials) == "table" then
    for index = 1, 48 do
      local value = Color.parse(stored.materials[index])
      if value ~= nil then
        state.materials[index] = value
      end
    end
  end
  local recent = readJson(directory .. "/recent-colors.json")
  if recent ~= nil then
    for index = 1, math.min(16, #recent) do
      local value = Color.parse(recent[index])
      if value ~= nil then
        table.insert(state.recent, value)
      end
    end
  elseif stored ~= nil and type(stored.recent) == "table" then
    for index = 1, math.min(16, #stored.recent) do
      local value = Color.parse(stored.recent[index])
      if value ~= nil then
        table.insert(state.recent, value)
      end
    end
  end
  local activeValue = stored and Color.parse(stored.active) or nil
  if activeValue ~= nil then
    state.active = activeValue
    state.materials[state.selected] = activeValue
    if activeValue.h >= 0 then
      state.hue = math.floor(activeValue.h + 0.5)
    end
  else
    state.active = state.materials[state.selected]
    if state.active.h >= 0 then
      state.hue = math.floor(state.active.h + 0.5)
    end
  end
  state.status = ""
  return state
end

local function makePaletteCss(Color, state)
  local rows = Color.paletteCssRows(state.active)
  local lines = {
    ":root {",
    "    --chromack-active: " .. Color.toCss(state.active) .. ";",
  }
  for _, row in ipairs(rows) do
    local key = string.lower(row.name)
    key = string.gsub(key, "[^a-z0-9]+", "-")
    key = string.gsub(key, "^-+", "")
    key = string.gsub(key, "-+$", "")
    table.insert(lines, "    --chromack-" .. key .. ": " .. Color.toCss(row.color) .. ";")
  end
  table.insert(lines, "}")
  return table.concat(lines, "\n") .. "\n"
end

local function makeMaterialCss(Color, state)
  local lines = { ":root {" }
  for index, color in ipairs(state.materials) do
    table.insert(lines, "    " .. Color.materialKey(index) .. ": " .. Color.toCss(color) .. ";")
  end
  table.insert(lines, "}")
  return table.concat(lines, "\n") .. "\n"
end

function M.persist(Color, state)
  local directory, err = noctalia.pluginDataDir()
  if type(directory) ~= "string" then
    return false, err or "Noctalia plugin data directory is unavailable."
  end
  local materials = {}
  for index, color in ipairs(state.materials) do
    materials[index] = Color.toCss(color)
  end
  local recent = {}
  for index, color in ipairs(state.recent) do
    recent[index] = Color.toCss(color)
  end
  local document = {
    selected = state.selected,
    hue = state.hue,
    active = Color.toCss(state.active),
    materials = materials,
    recent = recent,
  }
  local activeFile = Color.materialKey(state.selected) .. "\n" .. Color.toCss(state.active) .. "\n"
  local activeJson = noctalia.json.encode(document)
  local materialsJson = noctalia.json.encode(materials)
  local recentJson = noctalia.json.encode(recent)
  local recentText = #recent > 0 and (table.concat(recent, "\n") .. "\n") or ""
  local writes = {
    { "state.json", activeJson },
    { "active-color.txt", activeFile },
    { "materials.json", materialsJson },
    { "recent-colors.json", recentJson },
    { "recent-colors.txt", recentText },
    { "colors.css", makePaletteCss(Color, state) },
    { "material.css", makeMaterialCss(Color, state) },
  }
  for _, entry in ipairs(writes) do
    local ok, writeError = writeFile(directory .. "/" .. entry[1], entry[2])
    if not ok then
      return false, writeError
    end
  end
  return true
end

local function sanitizeFileBase(name)
  local base = string.lower(string.match(name, "^%s*(.-)%s*$"))
  base = string.gsub(base, "[^a-z0-9._-]+", "-")
  base = string.gsub(base, "%-+", "-")
  base = string.gsub(base, "^[%.%-]+", "")
  base = string.gsub(base, "[%.%-]+$", "")
  return base ~= "" and base or "palette"
end

local function tomlQuote(value)
  value = string.gsub(value, "\\", "\\\\")
  value = string.gsub(value, '"', '\\"')
  value = string.gsub(value, "\n", "\\n")
  value = string.gsub(value, "\r", "\\r")
  return '"' .. value .. '"'
end

function M.exportPalette(Color, state, requestedName)
  local title = string.match(requestedName or "", "^%s*(.-)%s*$")
  if title == "" then
    title = "Palette"
  end
  local directory, err = noctalia.pluginDataDir()
  if type(directory) ~= "string" then
    return nil, err or "Noctalia plugin data directory is unavailable."
  end
  local palettesDirectory = directory .. "/palettes"
  local ok, mkdirError = noctalia.mkdirAll(palettesDirectory)
  if not ok then
    return nil, mkdirError or "Could not create the palette directory."
  end
  local base = sanitizeFileBase(title)
  local path
  local suffix = 1
  repeat
    local name = base .. (suffix == 1 and "" or "-" .. tostring(suffix)) .. ".toml"
    path = palettesDirectory .. "/" .. name
    suffix += 1
  until not noctalia.fileExists(path)
  local rows = Color.palette(state.active)
  local lines = {
    "[palette]",
    "name = " .. tomlQuote(title),
    "base = " .. tomlQuote(Color.toPaletteFileColor(state.active)),
    "",
    "[colors]",
  }
  for _, row in ipairs(rows) do
    local key = string.lower(row.name)
    key = string.gsub(key, "[^a-z0-9]+", "_")
    key = string.gsub(key, "^_+", "")
    key = string.gsub(key, "_+$", "")
    table.insert(lines, key .. " = " .. tomlQuote(Color.toPaletteFileColor(row.color)))
  end
  local saveOk, saveError = writeFile(path, table.concat(lines, "\n") .. "\n")
  if not saveOk then
    return nil, saveError
  end
  return path
end

return M
