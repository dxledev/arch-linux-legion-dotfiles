# Layout

Enable `dxle/layout-menu` in **Settings → Plugins**. Use `SUPER+ALT+L` to toggle the launcher with `>layout` prefilled, or type `>layout` in the launcher. Adding `dxle/layout-menu:switcher` to the bar is optional; its click action opens the same launcher list.

The panel defaults to 700 × 480 logical pixels. Its width setting supports 600–1200 in steps of 10. Launcher settings match Shell Mode: enabled, prefix `layout`, global search off. Searches match display names and layout IDs case-insensitively and preserve menu order.

The bundled Bash helper supports `--list`, `--apply ID`, `--dry-run ID`, and `--help`. Set `DESKTOP_SCRIPTS_DIR` to an absolute directory (default `~/bin`) containing `lib-hypr-lua` and `menu-layout`. Listing reads the resolved Hyprland decorations Lua/config file; application delegates to `menu-layout --layout ID`, preserving persistence, notifications, animations, and Scrolling axis save/restore. Selecting the active layout does nothing except Scrolling, which is reapplied.

`build-noctalia` installs a symlink using `NOCTALIA_LAYOUT_MENU_PLUGIN_SOURCE` and `NOCTALIA_LAYOUT_MENU_PLUGIN_TARGET` overrides. Run `build-noctalia --dry-run` to review paths.

Status is refreshed on opens, queries, and activation. Failed status reads prevent application. Panel failures remain visible; launcher failures notify. Closing a panel invalidates pending status work; an already started helper may finish. Rendered panel comparison and launcher/keybinding acceptance require a running Noctalia session.

Run automated checks from the plugin directory:

```bash
python3 tests/check.py
lua tests/async.lua "$PWD"
```

The async harness uses mocked APIs and converts Luau's increment syntax for Lua. It checks callback behavior; native plugin lint and a running session provide separate validation.
