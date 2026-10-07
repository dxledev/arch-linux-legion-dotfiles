local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local root_path = os.getenv("HYPRLAND_CONFIG") or (config_home .. "/hypr/hyprland.lua")
local layout_path = os.getenv("HYPRMONCFG_MONITORS_CONF") or (config_home .. "/hypr/hyprmoncfg-monitors.lua")

local function layout_is_included()
    local file = io.open(root_path, "r")
    if not file then
        return false
    end
    local included = false
    for line in file:lines() do
        local statement = line:match("^%s*(.-)%s*$")
        if statement:sub(1, 2) ~= "--" and statement:find("hyprmoncfg-monitors", 1, true)
            and statement:find("dofile(", 1, true) then
            included = true
            break
        end
    end
    file:close()
    return included
end

local function reset_disabled(rule)
    -- Lua monitor rules merge, while the backend omits false for enabled outputs.
    hl.monitor({ output = rule.output, disabled = rule.disabled == true })
end

if layout_is_included() then
    local file = io.open(layout_path, "r")
    if file then
        file:close()
        local environment = {
            hl = { monitor = reset_disabled, workspace_rule = function() end },
            _G = {},
        }
        assert(loadfile(layout_path, "t", environment))()
    end
end
