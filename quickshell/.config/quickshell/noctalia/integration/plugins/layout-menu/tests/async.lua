local plugin = assert(arg[1])
local pending, rendered, results, notices, closes = {}, nil, {}, {}, 0
local failStart = false
noctalia = {
  pluginDir = function() return plugin end,
  json = { decode = function(value) return value end },
  runAsync = function(command, callback)
    if failStart then return false end
    table.insert(pending, { command = command, callback = callback })
    return true
  end,
  notifyError = function(_, message) table.insert(notices, message) end,
}
local layouts = dofile(plugin .. '/lib/layouts.luau')
require = function() return layouts end
ui = {}
for _, kind in ipairs({'label', 'button', 'row', 'column'}) do
  ui[kind] = function(props, children) return { kind = kind, props = props, children = children } end
end
panel = { render = function(tree) rendered = tree end, close = function() closes = closes + 1 end }
launcher = { setResults = function(query, rows) results[query] = rows end }
local function loadEntry(name)
  local file = assert(io.open(plugin .. '/' .. name))
  local source = file:read('*a'); file:close()
  source = source:gsub('generation %+= 1', 'generation = generation + 1')
  assert(load(source, name))()
end
local function status(index, active, failure)
  local rows = {}
  for _, entry in ipairs(layouts.entries) do
    table.insert(rows, { id = entry.id, name = entry.name, current = entry.id == active })
  end
  pending[index].callback({ exitCode = failure and 1 or 0, stdout = rows })
end
local function click(index) rendered.children[index + 1].children[1].props.onClick() end
loadEntry('menu.luau')
onOpen(); onClose(); status(1, 'dwindle')
assert(rendered.children[2].kind == 'label')
onOpen(); onOpen(); status(2, 'master')
assert(rendered.children[2].kind == 'label')
status(3, 'dwindle')
assert(#rendered.children == 9)
assert(rendered.props.padding == 16 and rendered.props.gap == 12)
assert(rendered.children[2].children[1].props.selected)
click(3); assert(#pending == 4)
onClose(); status(4, 'dwindle'); assert(#pending == 4)
onOpen(); status(5, 'dwindle'); click(3); status(6, 'dwindle')
assert(pending[7].command[3] == '--apply' and pending[7].command[4] == 'master')
pending[7].callback({exitCode = 1}); assert(closes == 0)
assert(rendered.children[2].props.color == 'error')
onOpen(); status(8, 'scrolling'); click(2); status(9, 'scrolling')
assert(pending[10].command[3] == '--apply')
pending[10].callback({exitCode = 0}); assert(closes == 1)
onOpen(); status(11, 'master'); click(3); status(12, 'master')
assert(#pending == 12 and closes == 2)
onOpen(); status(13, nil, true); assert(rendered.children[2].props.color == 'error')
loadEntry('providers.luau')
onQuery('grid'); onQuery('LUA:'); status(14, 'dwindle')
assert(results.grid[1].id == 'loading')
status(15, 'master'); assert(#results['LUA:'] == 4)
assert(results['LUA:'][1].id == 'lua:grid' and results['LUA:'][4].id == 'lua:centerstack')
onActivate('loading'); onActivate('invalid'); assert(#pending == 15)
onActivate('lua:grid'); onActivate('lua:grid'); assert(#pending == 16)
status(16, nil, true); assert(#notices == 1 and #pending == 16)
onQuery('CENTER-STACK'); status(17, 'master'); assert(results['CENTER-STACK'][1].id == 'lua:centerstack')
onQuery('absent'); status(18, 'master'); assert(results.absent[1].id == 'no-match')
onActivate('no-match'); assert(#pending == 18)
failStart = true
onQuery(''); assert(results[''][1].id == 'error')
print('Panel and launcher async fixtures passed')
