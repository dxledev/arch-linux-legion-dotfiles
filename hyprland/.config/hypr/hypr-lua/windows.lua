hl.window_rule({
  name = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  name = "fix-xwayland-drags",
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  no_focus = true,
})

hl.window_rule({
  name = "move-hyprland-run",
  match = { class = "hyprland-run" },
  move = "20 monitor_h-120",
  float = true,
})

hl.window_rule({ match = { class = "kitty" }, opacity = "0.92 0.92 0.92" })
hl.window_rule({ match = { class = "Alacritty" }, opacity = "0.92 0.92 0.92" })
hl.window_rule({ match = { class = "com.mitchellh.ghostty" }, opacity = "0.92 0.92 0.92" })
hl.window_rule({ match = { class = "chrome-chatgpt.com__-Default" }, opacity = "1 1.06 1.06" })
hl.window_rule({ match = { class = "chromium" }, opaque = true })
hl.window_rule({ match = { class = "Chromium" }, opaque = true })
hl.window_rule({ match = { class = "brave-browser" }, opaque = true })

hl.window_rule({
  name = "native-floating-terminal",
  float = true,
  size = { 1000, 800 },
  match = { tag = "scratchterm" },
  center = true,
  pin = true,
})

for _, target in ipairs({
  { title = "^(blackscreen-hdmi)$", monitor = "HDMI-A-1" },
  { title = "^(blackscreen-dp)$", monitor = "DP-1" },
}) do
  hl.window_rule({ match = { title = target.title }, monitor = target.monitor })
  hl.window_rule({ match = { title = target.title }, fullscreen = true })
  hl.window_rule({ match = { title = target.title }, no_anim = true })
end

hl.window_rule({ match = { float = false }, no_shadow = true })

local floating_rules = {
  { name = "float-localsend", class = "localsend", size = { 410, 580 } },
  { name = "float-qalculate", class = "io.github.Qalculate.qalculate-qt", size = { 400, 620 } },
  { name = "move-discord-to-discordspace", title = "Discord", workspace = "special:discordspace", size = { 1200, 800 } },
  { name = "move-discord-to-discordspace-two", title = "^(\\(\\d+\\)\\s*)?Discord.*", workspace = "special:discordspace", size = { 1200, 800 } },
  { name = "move-spotify-to-mediaspace", class = "spotify", workspace = "special:mediaspace", size = { 1200, 800 } },
  { name = "move-instagram-to-mediaspace", class = "^chrome-instagram\\.com__.*$", workspace = "special:socialspace", size = { 1200, 800 } },
  { name = "move-tiktok-to-mediaspace", class = "^chrome-tiktok\\.com__.*$", workspace = "special:socialspace", size = { 1200, 800 } },
  { name = "move-obsidian-to-scratchpad", class = "^(obsidian)$", workspace = "special:scratchpad", size = { 1200, 800 } },
}

for _, rule in ipairs(floating_rules) do
  local match = {}
  if rule.class then
    match.class = rule.class
  end
  if rule.title then
    match.title = rule.title
  end

  hl.window_rule({
    name = rule.name,
    match = match,
    workspace = rule.workspace,
    float = true,
    center = true,
    size = rule.size,
    animation = "slide bottom",
  })
end

hl.window_rule({
  name = "share-picker-pin",
  match = { class = "hyprland-share-picker" },
  size = { 1200, 800 },
  float = true,
  pin = true,
  center = true,
  animation = "slide bottom",
})

for _, namespace in ipairs({ "ward", "swayosd", "hypr-dock" }) do
  hl.layer_rule({
    name = namespace .. "-blur",
    match = { namespace = namespace },
    blur = true,
    ignore_alpha = 0.1,
  })
end

hl.layer_rule({
  name = "mako-slide-right",
  match = { namespace = "notifications" },
  animation = "slide right",
})

hl.layer_rule({
  name = "waybar-slide-top",
  match = { namespace = "waybar" },
  animation = "slide top",
})
