hl.monitor({
  output = "desc:ASUSTek COMPUTER INC ASUS VG277Q1A T1LMTF101706",
  mode = "1920x1080@144",
  position = "0x0",
  scale = 1,
})

hl.monitor({
  output = "desc:Acer Technologies KG271U N3 3511036353W01",
  mode = "2560x1440@144.01",
  position = "1920x0",
  scale = 1.25,
})

hl.monitor({
  output = "desc:BOE 0x0A2D",
  disabled = true,
})

for workspace = 1, 9 do
  hl.workspace_rule({
    workspace = tostring(workspace),
    monitor = "HDMI-A-1",
    persistent = false,
  })
end

for _, workspace in ipairs({ "special:discordspace", "special:mediaspace", "special:scratchpad", "special:socialspace" }) do
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
