local plugin_keywords = {
  "plugin:hyprexpo:columns 3",
  "plugin:hyprexpo:gap_size 5",
  "plugin:hyprexpo:bg_col rgb(000000)",
  "plugin:hyprexpo:workspace_method center current",
  "plugin:hyprexpo:skip_empty false",
  "plugin:dynamic-cursors:enabled true",
  "plugin:dynamic-cursors:mode none",
  "plugin:dynamic-cursors:threshold 2",
  "plugin:dynamic-cursors:rotate:length 20",
  "plugin:dynamic-cursors:rotate:offset 0.0",
  "plugin:dynamic-cursors:tilt:limit 5000",
  "plugin:dynamic-cursors:tilt:function negative_quadratic",
  "plugin:dynamic-cursors:tilt:window 100",
  "plugin:dynamic-cursors:tilt:full_tilt 60",
  "plugin:dynamic-cursors:stretch:limit 3000",
  "plugin:dynamic-cursors:stretch:function quadratic",
  "plugin:dynamic-cursors:stretch:window 100",
  "plugin:dynamic-cursors:shake:enabled true",
  "plugin:dynamic-cursors:shake:nearest false",
  "plugin:dynamic-cursors:shake:threshold 8.0",
  "plugin:dynamic-cursors:shake:base 2.0",
  "plugin:dynamic-cursors:shake:speed 2.0",
  "plugin:dynamic-cursors:shake:influence 0.0",
  "plugin:dynamic-cursors:shake:limit 4.0",
  "plugin:dynamic-cursors:shake:timeout 1500",
  "plugin:dynamic-cursors:shake:effects false",
  "plugin:dynamic-cursors:shake:ipc false",
  "plugin:dynamic-cursors:hyprcursor:nearest false",
  "plugin:dynamic-cursors:hyprcursor:enabled false",
  "plugin:dynamic-cursors:hyprcursor:resolution -1",
  "plugin:dynamic-cursors:hyprcursor:fallback clientside",
}

local function keyword_command(keyword)
  return "hyprctl keyword " .. keyword
end

local function apply_plugin_keywords()
  for _, keyword in ipairs(plugin_keywords) do
    hl.exec_cmd(keyword_command(keyword))
  end
end

hl.on("hyprland.start", function()
  local commands = { "hyprpm reload -nn" }
  for _, keyword in ipairs(plugin_keywords) do
    table.insert(commands, keyword_command(keyword))
  end
  table.insert(commands, "hyprctl dismissnotify")
  hl.exec_cmd(table.concat(commands, " && "))
end)

hl.on("config.reloaded", apply_plugin_keywords)
