local M = {}
M.entries = {
  { id = "dwindle", name = "Dwindle" },
  { id = "scrolling", name = "Scrolling" },
  { id = "master", name = "Master" },
  { id = "monocle", name = "Monocle" },
  { id = "lua:grid", name = "Grid" },
  { id = "lua:spiral", name = "Spiral" },
  { id = "lua:manual", name = "Manual" },
  { id = "lua:centerstack", name = "Center-Stack" },
}
M.statusError = "Could not read the active layout. No change was made."

function M.valid(id)
  for _, entry in ipairs(M.entries) do
    if entry.id == id then return true end
  end
  return false
end

local function command(operation, id)
  local args = { "/usr/bin/bash", noctalia.pluginDir() .. "/layout-menu", operation }
  if id ~= nil then table.insert(args, id) end
  return args
end

function M.decode(result)
  if result.exitCode ~= 0 or result.timedOut then return nil end
  local ok, entries = pcall(noctalia.json.decode, result.stdout or "")
  if not ok or type(entries) ~= "table" or #entries ~= #M.entries then return nil end
  local active = nil
  for index, expected in ipairs(M.entries) do
    local entry = entries[index]
    if type(entry) ~= "table" or entry.id ~= expected.id or entry.name ~= expected.name
      or type(entry.current) ~= "boolean" then return nil end
    if entry.current then
      if active ~= nil then return nil end
      active = entry.id
    end
  end
  return active
end

function M.read(callback)
  local started = noctalia.runAsync(command("--list"), function(result)
    callback(M.decode(result))
  end)
  if not started then callback(nil) end
end

function M.activate(id, isCurrent, callback)
  if not M.valid(id) then return end
  M.read(function(active)
    if not isCurrent() then callback(false, nil); return end
    if active == nil then callback(false, M.statusError); return end
    if active == id and id ~= "scrolling" then callback(true); return end
    local started = noctalia.runAsync(command("--apply", id), function(result)
      local success = result.exitCode == 0 and not result.timedOut
      callback(success, success and nil or "Could not apply the layout.")
    end)
    if not started then callback(false, "Could not start the layout helper.") end
  end)
end

return M
