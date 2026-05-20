local disabled_permissions = {
  { "/usr/(bin|local/bin)/grim", "screencopy", "allow" },
  { "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow" },
  { "/usr/(bin|local/bin)/hyprpm", "plugin", "allow" },
}

local smart_gap_workspace_rules = {
  { workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 },
  { workspace = "f[1]", gaps_out = 0, gaps_in = 0 },
}

local smart_gap_window_rules = {
  {
    name = "no-gaps-wtv1",
    match = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding = 0,
  },
  {
    name = "no-gaps-f1",
    match = { float = false, workspace = "f[1]" },
    border_size = 0,
    rounding = 0,
  },
}

return {
  disabled_permissions = disabled_permissions,
  smart_gap_workspace_rules = smart_gap_workspace_rules,
  smart_gap_window_rules = smart_gap_window_rules,
}
