Hyprspace is intentionally disabled in this Hyprland config.

The binary in this directory was built from KZDKM/Hyprspace PR 231 at
bf2ef21007e8963fcb0016ae26b6b21704946f80 with local compatibility patches:

- Lua bridge for `hl.plugin.hyprspace.toggle/open/close`
- `plugin:overview:renderWindows`
- `plugin:overview:renderLayers`

It crashed this Hyprland 0.55 NVIDIA/AMD hybrid session, so `plugins.lua` keeps
`enable_hyprspace = false` until a live test is explicitly allowed. The safe test
profile sets `renderWindows = 0`, `renderLayers = 0`, and `disableBlur = 1`.
