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
- `caelestia/integration/Colors.qml`: maps the active system theme's authored colours directly to the shell's Material roles. While Dynamic is active, `caelestia/integration/shell-theme` either generates a wallpaper-derived palette or imports the palette applied by Aether.
- `caelestia/integration/Typography.qml`: watches Ghostty's font setting, falling back to Alacritty. `~/bin/font` therefore updates shell fonts too.
- `caelestia/integration/NotificationFormat.qml`: renders notification markup using Ward's parser, with styled previews and rich expanded titles/bodies. Theme variables come from `themes/current/ward.css` plus shared `Colors.qml` names; override the stylesheet with `SHELL_NOTIFICATION_STYLE`. Rebuild its native module with `scripts/build-integration` after Qt upgrades.
- `caelestia/integration/NotificationReplacements.qml`: uses `/usr/bin/dbus-monitor` to detect replacement requests, including identical content. Each replacement restarts the popup timeout and can show an expired popup again, respecting DND and hover pauses.
- `caelestia/integration/WindowRounding.qml`: follows `border.rounding` in `shell.json` (default 25), using circular corners (`power: 2`). Reapplies after Hyprland reloads while Quickshell mode is selected. Waybar restores the normal Hyprland configuration.
- `caelestia/integration/hyprland.lua`: loaded through `active` at the end of the Hyprland config and applied only in Quickshell mode.

The wallpaper selector previews highlighted images live through `awww`, using a horizontal wipe with a soft fade (0.65 seconds, 144 FPS, color step 3). Closing the selector restores the saved wallpaper; confirming saves the current theme's wallpaper link. Rapid navigation coalesces pending previews so the latest selection wins. Set `AWWW_TRANSITION`, `AWWW_TRANSITION_DURATION`, `AWWW_TRANSITION_ANGLE`, `AWWW_TRANSITION_STEP`, or `AWWW_TRANSITION_FPS` in the shell environment to customize the effect. Preview the command with `integration/system-action --dry-run wallpaper-preview /absolute/image/path`. The existing `awww` slideshow continues to work. Hyprlock/hypridle, SwayOSD, OBS recording tools, and the system theme scripts remain the configured providers; Caelestia's parallel wallpaper, lock, idle and recording workflows are disabled or routed to them.

The original right-edge Caelestia OSD is enabled alongside SwayOSD. It includes volume plus Primary (HDMI-A-1) and Secondary (DP-1) brightness sliders; hover the right edge to open it and hover a brightness slider to see its label. Configure the monitor list and labels in `caelestia/config/integration.json` under `brightnessMonitors`. Brightness uses DDC and shares the lock/cache used by `~/bin/system-brightness-{hdmi,dp}`; readings synchronize through file-change notifications, with no recurring hardware polling. Use `qs ipc call brightness refresh` after changes made with a monitor’s physical buttons. `brightnessWriteDelay` in `integration.json` controls the minimum interval between queued writes (default 100 ms). Preview an absolute adjustment with `/usr/bin/bash integration/monitor-brightness --dry-run HDMI-A-1 BUS set 50` (substitute the detected I2C bus number).

Caelestia owns notifications in Quickshell mode. `~/bin/toggle-shell-mode` stops Ward's systemd service before starting it, and restores Ward in Waybar mode. The theme script respects that ownership. The missing profile photo uses a placeholder; choose a photo in the dashboard to create `~/.face`.

Theme refreshes resolve the wallpaper directory's symlink target and rebuild the selector against that directory, including thumbnail paths and categories. The three-second wallpaper poll also detects changes made outside the theme command. Switching themes clears previews from the previous theme. Wallpapers sort by their leading number; labels follow `~/bin/bg-set`: no number prefix or extension, spaces instead of dashes/underscores, capitalized words, and a `(Live)` suffix for GIFs.

The bottom launcher's Commands → Theme entry opens a searchable theme submenu beside Wallpaper. Names and palette wheels reuse `~/bin/menu-theme`'s parser; the current theme has a checkmark. The additional Dynamic entry uses a sparkle icon and derives Caelestia's colours from wallpapers in `~/files/pictures/wallpapers/dynamic/caelestia` without changing the system theme. Its selected wallpaper is stored through `~/.local/state/caelestia/dynamic-wallpaper`, so the Dynamic picker and Random action never rewrite a named theme's wallpaper. Variant and Light/Dark Mode appear only while Dynamic is active; named themes always retain their authored shell colours and mode. Selecting a named theme still runs `~/bin/theme`; selecting the already-applied theme only changes Caelestia back from Dynamic to the fixed system palette. The selection and Dynamic preferences are stored in `~/.local/state/caelestia/shell-theme.json`, and generated Dynamic palettes are cached under `~/.cache/caelestia/shell-theme`. Override the Dynamic directory with `CAELESTIA_DYNAMIC_WALLPAPERS_DIR`. Use `caelestia/integration/shell-theme --dry-run refresh` to inspect an update and `caelestia/integration/theme-list --dry-run` to list themes without generating icons.

Confirmed Dynamic changes also render a complete application palette at `~/.config/themes/.dynamic/caelestia`. General desktop consumers follow the hidden `~/.config/themes/.caelestia-use` selector, while the Waybar process stack continues to follow `themes/current`. `~/bin/theme-apply [--dry-run] system|dynamic` owns selector activation and application reloads; `caelestia/integration/theme-render [--dry-run] [--force] PALETTE_JSON ABSOLUTE_WALLPAPER` owns only the generated theme directory. Entering Waybar restores the selector and desktop applications to `current`; starting Caelestia refreshes the saved shell state and restores Dynamic when selected. Dynamic Spotify colors are exposed through `~/.config/spicetify/Themes/CaelestiaDynamic` without changing named-theme mappings.

Commands → Browse Wallpapers is available only while Dynamic is selected. It and Settings → Wallpaper & Style → Aether both run `caelestia/integration/aether launch`. The launcher opens Aether's Theme Editor as one native Wayland window, floating and centered at 1320×880 on `special:aether`. A second launch reveals and focuses that client instead of starting another process. The Caelestia tray shows an Aether item while the process is running; clicking it reveals Aether, and its tray menu can open or terminate the process. Hiding or moving the client does not remove the tray item, while quitting Aether does.

Aether is Dynamic's wallpaper and palette editor, not a separate shell theme. Apply first writes its normal outputs under `~/.config/aether/theme/`, including `colors.toml` and `backgrounds/`. The managed custom template at `~/.config/aether/custom/caelestia` then runs `caelestia/integration/aether apply`, which imports the edited palette as Dynamic, atomically saves the edited background under `~/files/pictures/wallpapers/dynamic/caelestia`, updates `~/.local/state/caelestia/dynamic-wallpaper`, and sends that saved copy through `awww`. Choosing another Dynamic wallpaper or changing its variant or mode switches back to Caelestia's wallpaper-derived palette. Aether Apply does not run `~/bin/theme` or rewrite a named theme's `wallpaper.png`.

The checksum-verified Aether v4.29.8 executable is kept in the ignored `.runtime/aether/bin/aether` path (SHA-256 `d3d2d07b32da7a495221ed271ee66f4a1e344c91dcec9b267ec0a74ab6e36462`). Arch also needs `webkit2gtk-4.1`, installed with `sudo pacman -S --needed webkit2gtk-4.1`. Aether's control socket and PID file are `~/.config/aether/aether.sock` and `~/.config/aether/aether.sock.pid`; launcher diagnostics are written to `~/.local/state/caelestia/aether.log`. Use `caelestia/integration/aether status`, `caelestia/integration/aether --dry-run launch`, `caelestia/integration/aether --dry-run quit`, `caelestia/integration/aether --dry-run apply`, `caelestia/integration/shell-theme --dry-run set-aether /absolute/colors.toml`, and `qs ipc call theme aetherPalette` for non-mutating checks. Override the executable, applied palette, or Aether output wallpaper directory with `AETHER_BIN`, `AETHER_THEME_FILE`, or `AETHER_WALLPAPERS_DIR` respectively.

Optional environment overrides: `QUICKSHELL_ROOT`, `QUICKSHELL_RUNTIME`, `SHELL_THEME_FILE`, `SHELL_THEMES_DIR`, `SHELL_WALLPAPER`, `SHELL_DYNAMIC_WALLPAPER`, `CAELESTIA_DYNAMIC_WALLPAPERS_DIR`, `AETHER_BIN`, `AETHER_THEME_FILE`, `AETHER_WALLPAPERS_DIR`, `SHELL_PROFILE_PICTURE`, `DESKTOP_SCRIPTS_DIR`, and `QS_ICON_THEME` (default Papirus). Machine-specific application commands and directories are in `shell.json`. The launcher wrapper supplies the runtime paths and exports the icon theme before Qt initializes; a QML environment pragma is too late for icon lookup. For a direct launch, use `QS_ICON_THEME=Papirus qs`; the two default runtime paths in `caelestia/shell.qml` support this.

## Controls

| Key | Action |
| --- | --- |
| Super+Space | Launcher |
| Super+Shift+D | Dashboard |
| Super+Shift+N | Notifications |
| Super+D | Utilities |
| Super+Shift+B | Session menu |
| Super+Shift+C | Chromack |
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

## Chromack

Super+Shift+C toggles Chromack connected to the bottom border of the focused monitor, using `qs ipc call chromack toggle`. The launcher’s Commands → Chromack entry (`>chromack`) and `qs ipc call chromack open` open it; repeating the open command focuses it. X or Escape while the panel has focus also closes it. Outside clicks leave it open. Chromack and the launcher replace each other: opening either dismisses the other. Chromack retains its selected tab and active color. The eyedropper temporarily hides Chromack, then restores it on completion or cancellation. `qs ipc call chromack isOpen` reports its logical open state, including during picking.

The Color Picker, Shade, Palette, and Theory tabs use Chromack's original color algorithms and data formats. Styling comes from `~/.config/chromack/config.toml` and its CSS imports, including the current system theme. Recent colors, active color, material edits, and saved TOML palettes use the existing Chromack paths. Generated palette rows are read-only, as in standalone Chromack. Existing standalone commands are unchanged.

Configure `chromack` in `caelestia/config/integration.json`: `width` (520 logical pixels), `height` (610 logical pixels), optional proportional `heightRatio` when `height` is omitted, `inputFontSize` (13 pixels), `duration` (220 ms), and optional `eyedropperCommand` (an argument array returning a color on stdout). The default picker is `/usr/bin/hyprpicker -a -b -f rgb -o '#{0:02X}{1:02X}{2:02X}'`; it returns directly to the shell rather than invoking standalone Chromack. Set `SHELL_CHROMACK_CONFIG_DIR` to use an alternate Chromack configuration directory.

Build with `scripts/build-chromack` (`--dry-run` supported), also included in `scripts/build-runtime`. The build runs native regression tests and installs `Shell.Chromack` into `.runtime/qml`. Restart the shell after QML or native module changes; JSON and CSS reload live.
