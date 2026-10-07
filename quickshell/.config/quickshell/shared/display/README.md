# Shared display configuration

Caelestia's Nexus Display page also saves monitor nicknames and side panel layout
preferences to `~/.config/hyprmoncfg/display-settings.json` (or
`$HYPRMONCFG_CONFIG_DIR/display-settings.json`). Future shell integrations must
read and watch the same file for nicknames; connector names remain the hardware
and IPC identifiers. Preserve unknown settings when saving this file.

Its `nicknames` object maps connectors to display labels. Clearing a nickname
restores the connector label. The `osdLayouts` object maps active monitor counts
(`"1"`, `"2"`, `"3"`) to `"local"` or `"combined"`. Caelestia defaults to local
volume–sunset–brightness stacks with one or three monitors, and the combined
volume/two-brightness layout with two monitors. Local brightness controls target
the monitor hosting the panel. Nexus brightness controls use those same monitor
objects, so both views track each other's changes.

Saved display layouts and workspace assignments belong to the Hyprland session.
Caelestia, Island, Noctalia and Waybar use the same configuration, including the
laptop panel's enabled state. Switching shells preserves the last saved layout.

`shared/display/backend` is the common CLI entry point. The single user service
`hyprmoncfgd.service` owns automatic profile selection and all layout writes.
Its binaries live in `.runtime/hyprmoncfg/bin`; all shells share the profile store
at `${XDG_CONFIG_HOME:-$HOME/.config}/hyprmoncfg` and the daemon socket at
`$XDG_RUNTIME_DIR/hyprmoncfgd.sock`.

The root Hyprland configuration loads `shared/display/monitor-rules.lua` before
the backend's generated monitor include, independently of the active shell.
The helper clears inherited disabled flags before the generated rules apply.
It only acts while the generated layout is included, preserving `unmanage`.
The backend's generated include stays last so its layout and workspace rules
override the base configuration in every shell.

Configure an already installed backend without reinstalling its binaries:

```bash
~/.config/quickshell/scripts/install-hyprmoncfg --configure-only --dry-run
~/.config/quickshell/scripts/install-hyprmoncfg --configure-only
```

For a new installation, use `--enable-service` instead of `--configure-only`.
Existing profiles are preserved. The Caelestia backend path and service link
remain compatibility entry points to these shared files.

## Future shell editors

Every future hyprmoncfg integration must use this same backend, daemon, profile
store and generated monitor file. Do not create per-shell profile copies or
services. Saved edits from any shell must be visible to every other shell.
Shell startup, shutdown and mode changes must not stop the shared daemon,
unmanage its configuration, or apply a separate default layout.

Native editors should read `editor_state` when opened, subscribe to daemon
`status` events, and refresh their state when the shared layout or profiles
change. Send writes and timed preview/commit/revert requests through the same
daemon IPC, following Caelestia's editor and preview guard. This also exposes
previews initiated by another client. Themes, window state and unsaved drafts
can belong to each shell; saved layouts and management state are shared.

`HYPRMONCFG_BIN`, `HYPRMONCFGD_BIN` and `HYPRMONCFG_CONFIG_DIR` override common
backend paths. The older `CAELESTIA_HYPRMONCFG_BIN` and
`CAELESTIA_HYPRMONCFGD_BIN` names remain supported as fallbacks. Alternate
configuration paths must be set consistently for the daemon and all clients.
`HYPRLAND_CONFIG` and `HYPRMONCFG_MONITORS_CONF` select alternate Hyprland root
and generated monitor files.
