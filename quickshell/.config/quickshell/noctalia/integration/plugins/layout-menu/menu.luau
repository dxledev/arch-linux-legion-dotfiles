local Layouts = require("./lib/layouts.luau")
local generation = 0
local activeLayout = nil
local loading = false
local applying = false
local errorMessage = nil
local selectLayout

local function render()
  local children = { ui.label({ text = "Layout", fontSize = 20, fontWeight = "bold" }) }
  if loading then
    table.insert(children, ui.label({ text = "Reading active layout…" }))
  elseif errorMessage ~= nil then
    table.insert(children, ui.label({ text = errorMessage, color = "error" }))
  else
    for _, entry in ipairs(Layouts.entries) do
      local target = entry
      table.insert(children, ui.row({ gap = 12, align = "center" }, {
        ui.button({
          text = target.name,
          glyph = "layout-dashboard",
          selected = target.id == activeLayout,
          flexGrow = 1,
          onClick = function() selectLayout(target.id) end,
        }),
        ui.label({ text = target.id == activeLayout and "Active layout" or "", width = 100 }),
      }))
    end
  end
  panel.render(ui.column({ gap = 12, padding = 16 }, children))
end

selectLayout = function(id)
  if loading or applying or not Layouts.valid(id) then return end
  applying = true
  loading = true
  errorMessage = nil
  render()
  local currentGeneration = generation
  Layouts.activate(id, function() return generation == currentGeneration end, function(success, message)
    applying = false
    if generation ~= currentGeneration then return end
    loading = false
    if success then panel.close(); return end
    errorMessage = message
    render()
  end)
end

function onOpen()
  generation += 1
  local currentGeneration = generation
  activeLayout = nil
  errorMessage = nil
  loading = true
  render()
  Layouts.read(function(active)
    if generation ~= currentGeneration then return end
    activeLayout = active
    loading = false
    errorMessage = active == nil and Layouts.statusError or nil
    render()
  end)
end

function onClose()
  generation += 1
end
