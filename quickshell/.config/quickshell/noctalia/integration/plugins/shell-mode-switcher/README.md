# Shell Mode

Switch between Waybar, Caelestia, and Noctalia with a native Noctalia panel or launcher provider.

- Add `dxle/shell-mode-switcher:switcher` from **Settings → Widgets → Bar**. Its left-click action opens the panel.
- Configure the launcher provider and panel settings from **Settings → Plugins**.
- Type `>shell` in the launcher to show the same three modes. This uses the configured `>` provider prefix.
- `SUPER+CTRL+ALT+Q` continues to use Noctalia's built-in dmenu picker.

The picker reads the active mode from `~/bin/toggle-shell-mode --status` whenever it opens. It does not switch if that lookup fails, and selecting the active mode is a no-op.
