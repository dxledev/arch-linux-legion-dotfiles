# Shared display configuration

- Saved monitor layouts and workspace assignments are shared across Caelestia,
  Island, Noctalia, Waybar and any future shell modes.
- All hyprmoncfg integrations must use `shared/display/backend`, the single
  `hyprmoncfgd.service`, the shared `~/.config/hyprmoncfg` profile store and
  `$XDG_RUNTIME_DIR/hyprmoncfgd.sock`. Follow `shared/display/README.md`.
- Future editors must synchronize through daemon IPC: read `editor_state`,
  subscribe to `status` events and send layout changes through the same daemon.
  Do not fork saved profiles or create a daemon per shell.
- Keep `shared/display/monitor-rules.lua` in the global Hyprland load path before
  the generated monitor include. Shell mode guards must not restrict it.
- Shell mode changes must preserve the shared daemon and saved layout. Keep
  themes and unsaved editor drafts local to their shell.
- Monitor nicknames live in the shared profile directory's
  `display-settings.json`. Future shell integrations must read and watch its
  `nicknames` map, preserve unknown settings, and keep connector IDs for routing.
