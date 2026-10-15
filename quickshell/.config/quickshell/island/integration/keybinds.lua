local config_file = assert(arg[1], "Island keybind configuration is required")
local bindings = {}
local current_submap = ""
local modifier_order = { "SUPER", "CTRL", "ALT", "SHIFT", "CAPS", "MOD2", "MOD3", "MOD5" }
local modifier_aliases = { CONTROL = "CTRL", MOD1 = "ALT", MOD4 = "SUPER", LOGO = "SUPER" }

local function normalize_shortcut(value)
    local modifiers, keys = {}, {}
    for part in tostring(value):gmatch("[^+]+") do
        local key = part:match("^%s*(.-)%s*$"):upper()
        key = modifier_aliases[key] or key
        local is_modifier = false
        for _, modifier in ipairs(modifier_order) do
            if key == modifier then
                modifiers[key] = true
                is_modifier = true
                break
            end
        end
        if not is_modifier then table.insert(keys, key) end
    end
    local parts = {}
    for _, modifier in ipairs(modifier_order) do
        if modifiers[modifier] then table.insert(parts, modifier) end
    end
    for _, key in ipairs(keys) do table.insert(parts, key) end
    return table.concat(parts, " + ")
end

local function stub()
    return setmetatable({}, {
        __index = function(value, key)
            local child = stub()
            rawset(value, key, child)
            return child
        end,
        __call = function() return stub() end,
    })
end

local hyprland = stub()

function hyprland.bind(shortcut, _, options)
    options = options or {}
    if type(options.description) ~= "string" or not options.description:match("%S") then return end
    table.insert(bindings, {
        shortcut = normalize_shortcut(shortcut),
        description = options.description,
        release = options.release == true,
        submap = current_submap,
    })
end

function hyprland.unbind(shortcut)
    local normalized = normalize_shortcut(shortcut)
    for index = #bindings, 1, -1 do
        if bindings[index].shortcut == normalized then table.remove(bindings, index) end
    end
end

function hyprland.submap(name, callback)
    local previous = current_submap
    current_submap = name == "reset" and "" or name
    if callback then
        callback()
        current_submap = previous
    end
end

local environment = {
    hl = hyprland, ipairs = ipairs, pairs = pairs, type = type, tostring = tostring,
    tonumber = tonumber, table = table, string = string, math = math,
    os = { getenv = os.getenv },
}
local chunk, load_error = loadfile(config_file, "t", environment)
if not chunk then error(load_error) end
chunk()

local function json_string(value)
    return '"' .. value:gsub('[%z\1-\31\\"]', function(character)
        return string.format("\\u%04x", character:byte())
    end) .. '"'
end

local records = {}
for _, binding in ipairs(bindings) do
    table.insert(records, string.format('{"shortcut":%s,"description":%s,"release":%s,"submap":%s}',
        json_string(binding.shortcut), json_string(binding.description), tostring(binding.release), json_string(binding.submap)))
end
print("[" .. table.concat(records, ",") .. "]")
