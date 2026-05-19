hl.workspace_rule({
  workspace = "10",
  layout = "dwindle",
})

hl.workspace_rule({
  workspace = "special:mediaspace",
  on_created_empty = "~/bin/launch-spotify",
})

hl.workspace_rule({
  workspace = "special:discordspace",
  on_created_empty = "~/bin/launch-discord",
})
