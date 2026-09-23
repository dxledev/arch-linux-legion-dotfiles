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
local generation = 0
local activeMode = nil
local loading = false
local errorMessage = nil

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

local function readStatus(currentGeneration, callback)
  local started = noctalia.runAsync({ modeScript, "--status" }, function(result)
    if generation ~= currentGeneration then
      return
    end
    callback(statusMode(result))
  end)
  if not started and generation == currentGeneration then
    callback(nil)
  end
end

local function render()
  local children = {
    ui.label({ text = "Shell mode", fontSize = 20, fontWeight = "bold" }),
  }

  if loading then
    table.insert(children, ui.label({ text = "Reading active shell…" }))
  elseif errorMessage ~= nil then
    table.insert(children, ui.label({ text = errorMessage, color = "error" }))
  else
    for _, mode in ipairs(modes) do
      local target = mode
      table.insert(children, ui.row({ gap = 12, align = "center" }, {
        ui.button({
          text = target.title,
          glyph = "arrows-left-right",
          selected = target.id == activeMode,
          flexGrow = 1,
          onClick = function()
            selectMode(target.id)
          end,
        }),
        ui.label({
          text = target.id == activeMode and "Active shell" or "",
          width = 100,
        }),
      }))
    end
  end

  panel.render(ui.column({ gap = 12, padding = 16 }, children))
end

local function showError(message)
  activeMode = nil
  loading = false
  errorMessage = message
  render()
end

function selectMode(targetId)
  if loading or not validModes[targetId] then
    return
  end
  loading = true
  errorMessage = nil
  render()
  local currentGeneration = generation
  readStatus(currentGeneration, function(active)
    if active == nil then
      showError("Could not read the active shell. No switch was made.")
      return
    end
    activeMode = active
    loading = false
    if active == targetId then
      render()
      return
    end
    local flag
    for _, mode in ipairs(modes) do
      if mode.id == targetId then
        flag = mode.flag
        break
      end
    end
    if flag == nil or not noctalia.runAsync({ modeScript, flag }) then
      showError("Could not start the shell mode transition.")
      return
    end
    panel.close()
  end)
end

function onOpen()
  generation += 1
  activeMode = nil
  errorMessage = nil
  loading = true
  render()
  local currentGeneration = generation
  readStatus(currentGeneration, function(active)
    if active == nil then
      showError("Could not read the active shell. No switch was made.")
      return
    end
    activeMode = active
    loading = false
    render()
  end)
end

function onClose()
  generation += 1
end
