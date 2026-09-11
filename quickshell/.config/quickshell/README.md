# Quickshell shells

The default shell is Caelestia, adapted from [caelestia-dots/shell](https://github.com/caelestia-dots/shell). The source clones live in `~/builds/shells`; the editable shell lives here in the dotfiles repository. Native libraries and the isolated CLI environment are in `.runtime/`, which Git ignores.

```text
~/.config/quickshell -> ~/dotfiles/quickshell/.config/quickshell
  active -> caelestia
  shell.qml -> active/shell.qml
  assets, components, modules, services, utils, integration -> active/…
  caelestia/
    config/              shell.json, integration.json, monitor overrides
    integration/         shared colors, fonts, window rounding, system actions, keybindings
    modules/             Caelestia panels
    services/            Caelestia services
  scripts/               launcher, selector, native dependency rebuild
  .runtime/              local compiled dependencies; rebuild on another machine
  .backups/              original Quickshell files; not tracked

~/.config/caelestia -> ../dotfiles/quickshell/.config/quickshell/caelestia/config
```

## Configuration

- `caelestia/config/shell.json`: appearance, applications, panels, paths, launcher actions, and services. Caelestia's settings window also saves here.
- `caelestia/config/integration.json`: workspace starting numbers and window rounding synchronization.
- `caelestia/config/monitors/DP-1/shell.json`: two workspaces on the secondary monitor. HDMI-A-1 uses the global nine-workspace count. Starts are 10 and 1 respectively. Clicking and scrolling workspaces uses Hymission.
- `caelestia/integration/Colors.qml`: maps `~/.config/themes/current/Colors.qml` to Material roles. `~/bin/theme` refreshes it through the existing `theme reloadColors` IPC. The scheme picker lists the system themes.
- `caelestia/integration/Typography.qml`: watches Ghostty's font setting, falling back to Alacritty. `~/bin/font` therefore updates shell fonts too.
- `caelestia/integration/NotificationFormat.qml`: renders notification markup using Ward's parser, with styled previews and rich expanded titles/bodies. Theme variables come from `themes/current/ward.css` plus shared `Colors.qml` names; override the stylesheet with `SHELL_NOTIFICATION_STYLE`. Rebuild its native module with `scripts/build-integration` after Qt upgrades.
- `caelestia/integration/WindowRounding.qml`: follows `border.rounding` in `shell.json` (default 25), using circular corners (`power: 2`). Reapplies after Hyprland reloads while Quickshell mode is selected. Waybar restores the normal Hyprland configuration.
- `caelestia/integration/hyprland.lua`: loaded through `active` at the end of the Hyprland config and applied only in Quickshell mode.

The wallpaper selector previews highlighted images live through `awww`, using a horizontal wipe with a soft fade (0.65 seconds, 60 FPS). Closing the selector restores the saved wallpaper; confirming saves the current theme's wallpaper link. Rapid navigation coalesces pending previews so the latest selection wins. Set `AWWW_TRANSITION`, `AWWW_TRANSITION_DURATION`, `AWWW_TRANSITION_ANGLE`, `AWWW_TRANSITION_STEP`, or `AWWW_TRANSITION_FPS` in the shell environment to customize the effect. Preview the command with `integration/system-action --dry-run wallpaper-preview /absolute/image/path`. The existing `awww` slideshow continues to work. Hyprlock/hypridle, SwayOSD, OBS recording tools, and the system theme scripts remain the configured providers; Caelestia's parallel wallpaper, lock, idle, OSD, and recording workflows are disabled or routed to them.

Caelestia owns notifications in Quickshell mode. `~/bin/toggle-shell-mode` stops Ward's systemd service before starting it, and restores Ward in Waybar mode. The theme script respects that ownership. The missing profile photo uses a placeholder; choose a photo in the dashboard to create `~/.face`.

Optional environment overrides: `QUICKSHELL_ROOT`, `QUICKSHELL_RUNTIME`, `SHELL_THEME_FILE`, `SHELL_THEMES_DIR`, `SHELL_WALLPAPER`, `SHELL_PROFILE_PICTURE`, `DESKTOP_SCRIPTS_DIR`, and `QS_ICON_THEME` (default Papirus). Machine-specific application commands and directories are in `shell.json`. The two default runtime paths in `caelestia/shell.qml` support launching plain `qs`; the launcher wrapper supplies these paths dynamically.

## Controls

| Key | Action |
| --- | --- |
| Super+Space | Launcher |
| Super+Shift+D | Dashboard |
| Super+Shift+N | Notifications |
| Super+D | Utilities |
| Super+Shift+B | Session menu |
| Super+Shift+C | Caelestia settings |
| Super+Ctrl+Alt+Q | Existing Waybar/Quickshell mode toggle |

```bash
~/.config/quickshell/scripts/select-shell --list
~/.config/quickshell/scripts/select-shell --status
~/.config/quickshell/scripts/select-shell --dry-run caelestia
~/.config/quickshell/scripts/select-shell caelestia
~/bin/toggle-shell-mode --quickshell --dry-run
qs ipc call integration status
qs ipc call theme reloadColors
```

The selector restarts the default shell if it is running, then reloads Hyprland. Use it after editing QML; JSON settings and shared palette/font changes reload live. Start through `~/bin/toggle-shell-mode --quickshell` so notification and panel ownership is coordinated. Avoid separately launching `caelestia/shell.qml` alongside the default shell.

To add another shell, create a sibling directory containing `shell.qml` and an `exports` file listing each top-level QML file or module directory that should appear under the root. See `caelestia/exports`. Run `select-shell --dry-run NAME`, then `select-shell NAME`. Root helper directory `scripts`, dotfiles, and `active` are reserved. Existing unmanaged root files are never overwritten by the selector. A shell may provide `integration/hyprland.lua` for its own mode-specific bindings.

## Rebuild

Installed official dependencies include Qt 6, Quickshell, NetworkManager, PipeWire, libqalculate, lm_sensors, ddcutil, power-profiles-daemon, aubio, brightnessctl, fish, and swappy. Building needs CMake, Ninja, Meson, a C/C++ compiler, pkg-config, FFTW, iniparser, Python with venv/pip, and Qt shader tools. Source versions are recorded in `caelestia/upstream.json`.

```bash
git clone https://github.com/caelestia-dots/shell.git ~/builds/shells/caelestia
git clone https://github.com/LukashonakV/cava.git ~/builds/shells/libcava
git clone https://github.com/soramanew/m3shapes.git ~/builds/shells/m3shapes
git clone https://github.com/caelestia-dots/cli.git ~/builds/shells/caelestia-cli
~/.config/quickshell/scripts/build-runtime --dry-run
~/.config/quickshell/scripts/build-runtime
```

Run clone commands only for missing directories. Set `SHELL_SOURCES`, `SHELL_BUILD_DIR`, or `BUILD_JOBS` to customize the build. The build installs native libraries locally and the CLI into a venv; it does not overwrite the edited QML. Rebuild after Qt ABI changes. Updating the source clone alone does not update the vendored shell: review and merge QML changes into `caelestia/`, preserving the integration changes. Keep the native plugin and vendored QML versions aligned.

## Validation

The native plugins built successfully on this machine. Live checks verified a single root shell instance, notification ownership, shared theme/font/wallpaper values, the launcher binding, panel loading, and a Waybar/Caelestia mode round trip. Hyprland reported no configuration errors. Bash, JSON, and Lua checks passed. Use `/usr/lib/qt6/bin/qmlformat` for QML checks; `/usr/bin/qmlformat` belongs to Qt 5. Notification formatting passed 12 Qt 6 regression checks and a live styled-popup check. Suspend, shutdown, locking, and hardware-changing actions were not invoked as tests.
