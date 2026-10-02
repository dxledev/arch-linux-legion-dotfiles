# Prompt Style

Choose an installed Starship style from Noctalia's searchable launcher, using the same native layout and spacing as other launcher providers.

- Enable **Prompt Style** in **Settings → Plugins**. Press `SUPER+SHIFT+ALT+P`, click its optional bar widget, or type `>prompt` in the launcher to open the searchable style list.
- Continue typing after `>prompt` to filter by style name or id. The provider prefix and global-search behavior are configurable in **Settings → Plugins**.
- The active style is marked as the current prompt. Applying a different style updates `starship.toml`, reloads the terminal, refreshes interactive Zsh prompts, and sends a notification.
- The optional `dxle/terminal-prompt:prompt` bar widget uses the same launcher view; its label and icon are configurable in **Settings → Widgets → Bar**.
- Applying a style uses `~/bin/starship-style`, `~/bin/reload-terminal`, and `~/bin/notify-send`.
