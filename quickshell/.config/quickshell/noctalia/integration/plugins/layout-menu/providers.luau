local Layouts = require("./lib/layouts.luau")
local generation = 0
local knownLayouts = {}
local applying = false

local function rows(active, query)
  local results = {}
  local needle = string.lower(query or "")
  for _, entry in ipairs(Layouts.entries) do
    if string.find(string.lower(entry.name .. " " .. entry.id), needle, 1, true) then
      knownLayouts[entry.id] = true
      table.insert(results, {
        id = entry.id,
        title = entry.name,
        subtitle = entry.id == active and "Active layout" or nil,
        glyph = "layout-dashboard",
      })
    end
  end
  if #results == 0 then
    return { { id = "no-match", title = "No matching layouts", glyph = "search" } }
  end
  return results
end

function onQuery(query)
  generation += 1
  local currentGeneration = generation
  knownLayouts = {}
  launcher.setResults(query, { { id = "loading", title = "Reading active layout…", glyph = "loader" } })
  Layouts.read(function(active)
    if generation ~= currentGeneration then return end
    if active == nil then
      launcher.setResults(query, { { id = "error", title = "Layouts unavailable", subtitle = Layouts.statusError, glyph = "alert-triangle" } })
      return
    end
    launcher.setResults(query, rows(active, query))
  end)
end

function onActivate(id)
  if applying or not knownLayouts[id] then return end
  applying = true
  local currentGeneration = generation
  Layouts.activate(id, function() return generation == currentGeneration end, function(success, message)
    applying = false
    if generation ~= currentGeneration then return end
    if not success then noctalia.notifyError("Layout", message) end
  end)
end
