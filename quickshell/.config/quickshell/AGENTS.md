# Temporary storage

- Use `~/builds/.tmp/` instead of `/tmp` for any directory expected to exceed
  1 GB, including build trees, caches and scratch output. Configure these paths
  before starting large jobs. If a temporary directory grows beyond 1 GB,
  relocate it to `~/builds/.tmp/` before continuing.

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

# Shared notification history

- Caelestia, Island, Noctalia and Waybar share notification history through
  `shared/notifications/history` and wardnc's JSONL store. Follow
  `shared/notifications/README.md`; do not add a per-shell history file.
- New shells load it at startup, append received non-transient notifications,
  and remove or clear records when the user does.

# Shared Dynamic wallpapers

- Caelestia, Island and Noctalia use one Dynamic wallpaper folder but each remembers
  its own applied wallpaper. Anything that renames or deletes a Dynamic wallpaper must
  call `shared/wallpapers/relink` so the other shells' references follow. Follow
  `shared/wallpapers/README.md`; always pass the state root explicitly.

# Shared clipboard

- Caelestia, Island and Noctalia share clipboard history and pins: history is
  cliphist's database, pins are the favorites store under
  `~/.local/share/caelestia/clipboard`. Follow `shared/clipboard/README.md`;
  do not add a per-shell history or pin store.
- A pin's hash is the SHA-256 of the exact payload bytes. Read payloads without
  trimming, add a pin's payload before its manifest entry, and keep the
  `{"version":1,"items":[...]}` manifest format other shells validate.
