local config_file = arg[1]

local function trim(value)
  return tostring(value):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalize_binding(value)
  local parts = {}

  for part in trim(value):gmatch("[^+]+") do
    local normalized = trim(part)
    if normalized ~= "" then
      table.insert(parts, normalized)
    end
  end

  return table.concat(parts, " + ")
end

local function stub()
  return setmetatable({}, {
    __index = function(table_value, key)
      local child = stub()
      rawset(table_value, key, child)
      return child
    end,
    __call = function()
      return stub()
    end,
  })
end

hl = stub()

local bindings = {}

function hl.unbind(binding)
  local key = normalize_binding(binding)
  for i = #bindings, 1, -1 do
    if bindings[i].key == key then table.remove(bindings, i) end
  end
end

function hl.bind(binding, _, flags)
  if type(flags) ~= "table" or type(flags.description) ~= "string" or flags.description == "" then
    return
  end

  table.insert(bindings, { key = normalize_binding(binding), description = flags.description })
end

local config_dir = config_file:match("^(.*)/[^/]+$")
if config_dir then
  package.path = config_dir .. "/?.lua;" .. package.path
end

local ok, err = pcall(dofile, config_file)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  os.exit(1)
end

dofile(arg[2])
for _, binding in ipairs(bindings) do
  print(binding.key .. " | " .. binding.description)
end
