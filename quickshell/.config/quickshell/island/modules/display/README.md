# Display layout editor

This is a copy of Caelestia's `modules/display/vendor` and `compat` editor and
controls, adapted to Island's theme, brightness service and native window focus.
Caelestia's implementation remains independent. Both copies retain the upstream
MIT licenses; source revisions are recorded in
[`caelestia/integration/display/pin.json`](../../../caelestia/integration/display/pin.json).

`services/DisplayService.qml` owns one editor and a persistent preview guard for
the Island shell. Settings → Displays and Island's `openDisplays` IPC action open
the same window. `ISLAND_DISPLAY_FONT` optionally overrides the menu font.

The editor's `integration/display/backend` wrapper invokes
[`shared/display/backend`](../../../shared/display/backend)
and connects to `$XDG_RUNTIME_DIR/hyprmoncfgd.sock`. It reads `editor_state`,
subscribes to status updates and sends edits and preview/commit/revert requests
to the existing daemon. No Island-specific daemon or saved profile store exists.
Monitor nicknames are read and watched by `services/DisplaySettings.qml` from the
shared `display-settings.json`, preserving other settings when saving.

Follow the [shared integration contract](../../../shared/display/README.md) for
installation and backend overrides. Window state and unsaved drafts stay local
to Island; saved layouts, profiles and workspace assignments are shared.
