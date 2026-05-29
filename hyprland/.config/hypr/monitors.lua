local monitor_configs = {
  {
    output = "desc:ASUSTek COMPUTER INC ASUS VG277Q1A T1LMTF101706",
    mode = "1920x1080@144",
    position = "0x0",
    scale = 1,
  },
  {
    output = "desc:Acer Technologies KG271U N3 3511036353W01",
    mode = "2560x1440@144.01",
    position = "1920x0",
    scale = 1.25,
  },
  {
    output = "desc:BOE 0x0A2D",
    disabled = true,
  },
}

-- these are the desired monitor configs i want to enable/disable
-- local correct_monitor_configs = {
--   {
--     output = "desc:ASUSTek COMPUTER INC ASUS VG277Q1A T1LMTF101706",
--     mode = "1920x1080@144",
--     position = "0x0",
--     scale = 1,
--   },
--   {
--     output = "desc:Acer Technologies KG271U N3 3511036353W01",
--     mode = "2560x1440@144.01",
--     position = "1920x0",
--     scale = 1.25,
--   },
--   {
--     output = "desc:BOE 0x0A2D",
--     mode = "2560x1440@165",
--     position = "3968x600",
--     scale = 1.6,
--   },
-- }

local special_workspaces = {
  "special:discordspace",
  "special:mediaspace",
  "special:scratchpad",
  "special:socialspace",
}

for _, monitor in ipairs(monitor_configs) do
  hl.monitor(monitor)
end

for workspace = 1, 9 do
  hl.workspace_rule({
    workspace = tostring(workspace),
    monitor = "HDMI-A-1",
    persistent = false,
  })
end

for _, workspace in ipairs(special_workspaces) do
  hl.workspace_rule({
    workspace = workspace,
    monitor = "HDMI-A-1",
    persistent = false,
  })
end

hl.workspace_rule({
  workspace = "10",
  monitor = "DP-1",
  persistent = true,
})
