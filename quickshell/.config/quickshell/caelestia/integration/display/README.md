# Display layout editor

Nexus → Display contains one action, **Open Layout Editor**. The command panel's
**Display** action (`>Display`) and `scripts/caelestia shell display open` open the
same floating window. Repeated opens focus it and preserve its draft.

The visual editor is adapted from [omarchy-hyprmoncfg](https://github.com/crmne/omarchy-hyprmoncfg).
Its QML and shared controls are vendored under `modules/display`, with their MIT
licenses. `pin.json` records the source revisions and backend checksum.

The compatibility module maps colours, selection contrast, fonts and rounding
to Caelestia's active palette and tokens. Brightness uses Caelestia's existing
service. Omarchy's optional desktop-wide text-size control is hidden.

The [shared display backend](../../../shared/display/README.md) owns layout validation, monitor and workspace configuration,
profile persistence and automatic switching. It supports Hyprland Lua configs.
Applying uses the upstream timed preview; a persistent shell service retains the
confirmation surface if the editor closes or its monitor disappears. Unconfirmed
changes roll back. Opening the editor only reads the current layout.

Install the pinned backend locally and enable its user service:

```bash
~/.config/quickshell/scripts/install-hyprmoncfg --enable-service --dry-run
~/.config/quickshell/scripts/install-hyprmoncfg --enable-service
```

Binaries live in `.runtime/hyprmoncfg/bin`; all shell modes share profiles in
`~/.config/hyprmoncfg`. The first service setup saves the current monitor state
as **Current Layout** before enabling automatic management, preserving the
existing arrangement instead of applying an automatic draft. The backend adds its generated
monitor include to the Hyprland config. Existing monitor rules stay in place.
The Lua compatibility helper clears inherited disabled flags for outputs enabled
in the generated layout. It runs before that include and only while management
is enabled, allowing a laptop panel disabled in the base config to be turned on.
It loads from the global Hyprland config in every shell mode. Saved layouts,
including laptop enablement, persist when switching shells. Future editors must
use the same daemon and profile store, following the shared integration contract.
The installer preserves an already configured service instead of replacing it.

Backend paths can be overridden with `HYPRMONCFG_BIN` and `HYPRMONCFGD_BIN`.
`CAELESTIA_HYPRMONCFG_BIN` and `CAELESTIA_HYPRMONCFGD_BIN` remain fallback aliases;
`HYPRMONCFG_CONFIG_DIR` selects another shared profile store.
`CAELESTIA_DISPLAY_TERMINAL` overrides the terminal launcher for the TUI.
