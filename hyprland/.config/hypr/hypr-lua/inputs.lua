hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "altwin:swap_lalt_lwin, caps:hyper",
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = false,
    },
  },
  gestures = {
    workspace_swipe_direction_lock = true,
    workspace_swipe_direction_lock_threshold = 10,
    workspace_swipe_forever = false,
  },
})

hl.gesture({
  fingers = 3,
  direction = "horizontal",
  action = "workspace",
})

hl.device({
  name = "epic-mouse-v1",
  sensitivity = -0.5,
})
