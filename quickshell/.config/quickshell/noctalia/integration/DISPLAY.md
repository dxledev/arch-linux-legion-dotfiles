# Native display layout editor

Open the launcher's **Displays** provider with `>Displays`, use
**Control Center → Monitor → Configure Monitors** or
**Settings → System → Open Layout Editor**,
or run:

```bash
~/.config/noctalia/.runtime/bin/noctalia msg display-open
```

`display-toggle` and `display-close` are also available. The Settings launcher
provider includes Display, so `>settings display` opens its search result directly.
The editor is a native xdg-toplevel window in the Noctalia process, opening at
1600×900 (limited to the output's available size). It uses the same application ID
as Settings, with a display-specific floating size rule in `~/.config/hypr/windows.lua`.
Repeated opens focus the existing editor and preserve its draft. No plugin or
Quickshell process is needed.

The Layout page supports dragging with edge snapping. The selected monitor's
**Display** tab contains enabling, resolution/refresh, scale, position,
rotation/flips, mirroring, VRR and hardware brightness. Its **Color** tab contains
color depth, color space/HDR, ICC and luminance settings. Hardware brightness uses
Noctalia's existing service and remains outside layout profiles. Identify labels connected
displays for three seconds. TUI launches the shared backend in a terminal.

Workspaces shows active monitors in the same arrangement as Layout, with their
assigned workspace IDs. Its canvas is read-only. The controls support sequential,
interleaved and manual assignments, monitor ordering, persistence and a preview
of generated workspace rules. Profiles can
be loaded, saved, previewed and deleted with confirmation. Saving a draft stores
it; Apply starts a 30-second preview. Keep changes commits it; Revert or timeout
restores the previous layout. Closing the editor during a preview retains a
confirmation window. Closing that confirmation reverts the preview.

The editor is inspired by the [omarchy-hyprmoncfg editor](https://github.com/crmne/omarchy-hyprmoncfg)
and uses the daemon's `editor_state` and `edit_profile` APIs for validation,
neighbor reflow and snapping. It subscribes to daemon `status` events, preserves
unsaved drafts, and requires Reset after the connected hardware changes. Previews
from another editor block conflicting writes.

All saved layouts, workspace assignments and automatic profile selection use the
[same backend, daemon and profile store](../../shared/display/README.md) as
Caelestia and the other shells. The native editor never installs its own daemon,
changes profiles on startup, or stops the shared service on shell exit. It reads
and watches shared `display-settings.json` nicknames while routing by connector.

`HYPRMONCFG_CONFIG_DIR` must match the daemon's shared profile directory.
`NOCTALIA_DISPLAY_BACKEND` overrides the shared backend path for TUI launching;
`NOCTALIA_DISPLAY_TERMINAL` overrides `~/bin/launch-terminal`. Both must be absolute.
Noctalia's font, palette, UI scale and window state stay local to Noctalia.

The code is carried by `0030-native-display-editor.patch`,
`0031-display-inspector-tabs.patch` and `0032-display-window-workspace-canvas.patch`
in the ordered managed integration.
Rebuild through `noctalia/integration/build-noctalia` (`--dry-run`
previews installation). The native `display_editor` test uses an isolated mock
Unix socket to verify drafts, previews, topology changes, errors and nicknames.
