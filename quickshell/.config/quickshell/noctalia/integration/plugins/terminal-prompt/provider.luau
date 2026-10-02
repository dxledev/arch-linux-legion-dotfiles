local knownStyles = {}
local queryGeneration = 0

local function scriptCommand(operation, styleId)
  local pluginDirectory = noctalia.pluginDir()
  if type(pluginDirectory) ~= "string" or pluginDirectory == "" then
    return nil
  end

  local command = { "/usr/bin/bash", pluginDirectory .. "/terminal-prompt", operation }
  if styleId ~= nil then
    table.insert(command, styleId)
  end
  return command
end

local function decodeStyles(result)
  if result.exitCode ~= 0 or result.timedOut then
    return nil
  end

  local decoded = noctalia.json.decode(result.stdout or "")
  if type(decoded) ~= "table" then
    return nil
  end

  local styles = {}
  for _, style in ipairs(decoded) do
    if type(style) == "table" and type(style.id) == "string" and type(style.name) == "string" then
      table.insert(styles, {
        id = style.id,
        name = style.name,
        current = style.current == true,
      })
    end
  end
  return styles
end

local function matchingStyles(styles, query)
  local results = {}
  local needle = string.lower(query or "")
  for _, style in ipairs(styles) do
    local searchableText = string.lower(style.name .. " " .. style.id)
    local score
    if needle ~= "" then
      score = noctalia.fuzzyScore(needle, searchableText)
    end
    if needle == "" or score ~= nil then
      local resultId = "style:" .. style.id
      knownStyles[resultId] = style
      local result = {
        id = resultId,
        title = style.name,
        subtitle = style.current and "Current prompt" or nil,
        glyph = "terminal",
      }
      if score ~= nil then
        result.score = score
      end
      table.insert(results, result)
    end
  end

  if #results == 0 then
    return { { id = "no-results", title = "No matching prompt styles", glyph = "search" } }
  end
  return results
end

function onQuery(query)
  queryGeneration += 1
  local currentGeneration = queryGeneration
  knownStyles = {}
  launcher.setResults(query, {
    { id = "loading", title = "Loading prompt styles…", glyph = "loader" },
  })

  local command = scriptCommand("--list")
  if command == nil then
    launcher.setResults(query, {
      { id = "error", title = "Prompt styles unavailable", glyph = "alert-triangle" },
    })
    return
  end

  local started = noctalia.runAsync(command, function(result)
    if queryGeneration ~= currentGeneration then
      return
    end
    local styles = decodeStyles(result)
    if styles == nil then
      launcher.setResults(query, {
        { id = "error", title = "Could not load prompt styles", glyph = "alert-triangle" },
      })
      return
    end
    knownStyles = {}
    launcher.setResults(query, matchingStyles(styles, query))
  end)
  if not started and queryGeneration == currentGeneration then
    launcher.setResults(query, {
      { id = "error", title = "Could not start prompt style helper", glyph = "alert-triangle" },
    })
  end
end

function onActivate(styleId)
  local style = knownStyles[styleId]
  if style == nil or style.current then
    return
  end

  local command = scriptCommand("--apply", style.id)
  if command == nil or not noctalia.runAsync(command) then
    noctalia.notifyError("Prompt Style", "Could not start the prompt style helper.")
  end
end
