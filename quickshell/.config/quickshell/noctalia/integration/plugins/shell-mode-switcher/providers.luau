local modeScript = noctalia.expandPath("~/bin/toggle-shell-mode")
local modes = {
  { id = "waybar", title = "Waybar", flag = "--waybar" },
  { id = "caelestia", title = "Caelestia", flag = "--caelestia" },
  { id = "noctalia", title = "Noctalia", flag = "--noctalia" },
}
local validModes = {
  waybar = true,
  caelestia = true,
  noctalia = true,
}

local function statusMode(result)
  if result.exitCode ~= 0 or result.timedOut then
    return nil
  end
  local active = string.match(result.stdout or "", "^%s*(.-)%s*$")
  if validModes[active] then
    return active
  end
  return nil
end

local function rows(active)
  local results = {}
  for _, mode in ipairs(modes) do
    table.insert(results, {
      id = mode.id,
      title = mode.title,
      subtitle = mode.id == active and "Active shell" or nil,
      glyph = "arrows-left-right",
    })
  end
  return results
end

local function showError(query)
  launcher.setResults(query, {
    {
      id = "status-error",
      title = "Shell mode unavailable",
      subtitle = "Could not read the active shell. No switch was made.",
      glyph = "alert-triangle",
    },
  })
end

local function readStatus(query, callback)
  local started = noctalia.runAsync({ modeScript, "--status" }, function(result)
    local active = statusMode(result)
    if active == nil then
      showError(query)
      return
    end
    callback(active)
  end)
  if not started then
    showError(query)
  end
end

function onQuery(query)
  launcher.setResults(query, {
    { id = "loading", title = "Reading active shell…", glyph = "loader" },
  })
  readStatus(query, function(active)
    launcher.setResults(query, rows(active))
  end)
end

function onActivate(id)
  if not validModes[id] then
    return
  end
  local target
  for _, mode in ipairs(modes) do
    if mode.id == id then
      target = mode
      break
    end
  end
  if target == nil then
    return
  end

  local started = noctalia.runAsync({ modeScript, "--status" }, function(result)
    local active = statusMode(result)
    if active == nil or active == target.id then
      return
    end
    noctalia.runAsync({ modeScript, target.flag })
  end)
  if not started then
    noctalia.log("Shell Mode could not read the active shell.")
  end
end
