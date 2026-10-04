# Island

Integrated [Luci](https://github.com/ElhamSadiqi/Luci) at commit `2627227ab797cf7933c5f39925911429e2ccf49b`. MIT license retained in `LICENSE`. Island runs from its own `shell.qml`; the root Caelestia exports stay attached to Caelestia.

Install desktop integration with `./island/integration/install --dry-run`, then `./island/integration/install`. The installer checks the inspected utility hashes, preserves existing hard links, saves backups in `~/.local/state/island/install-backups/`, registers `~/.config/hypr/island-mode-keybindings.lua`, and initializes Island state. It does not switch the running shell.

Switch with `/home/dxle/bin/toggle-shell-mode --island`, or select **Island** in Waybar's Rofi menu, Caelestia's shell mode launcher, or Noctalia's shell mode menu/launcher. `toggle-shell-mode --dry-run --island` previews the transition. Island itself has a native shell switcher.

| Shortcut | Island action |
| --- | --- |
| Super + Ctrl + Alt + Q | Shell mode switcher |
| Super + Shift + Ctrl + C | Island settings |
| Super + Alt + T | Theme selector |
| Super + Ctrl + Alt + Space | Wallpaper selector |
| Ctrl + Alt + Space | Next wallpaper |
| Ctrl + Alt + Shift + Space | Previous wallpaper |
| Super + Shift + D | Expand Island |
| Super + Alt + V / A | Controls |
| Super + Alt + P | Power menu |
| Super + Shift + L | Hyprlock |

The compact Island displays only the clock. The theme section shows the static theme name, or `dynamic`. The expanded view has a control center button with a sliders icon and a three-dot menu. It opens a dedicated panel for themes, wallpapers, settings, and shell switching.

Settings → Clock opens a dedicated panel for 12-hour time (AM/PM), font family, size (8–40 px), and bold weight, with a live preview. Clicking the compact or expanded clock switches between 12-hour and 24-hour time; the shared `clock12Hour` setting saves automatically and defaults to false. The expanded clock stays on the compact clock's center line, with the clock/date group centered vertically alongside the controls. The compact clock grows to fit larger text and updates the reserved height. Settings → OSD opens a separate panel for the volume, brightness, nightlight, and keyboard font, size, weight, icon size, percentage visibility, slider width/thickness/rounding, value animation, entrance/exit animation, and display duration. These settings save automatically; Clock and OSD fonts are independent.

Brightness OSDs appear on the monitor whose brightness changed. When only one monitor has an Island, brightness events from every monitor appear there with monitor labels; simultaneous changes stack sliders in connector order, with independent expiry. Per-monitor event files prevent concurrent shortcut commands from overwriting one another. Volume continues to appear on all enabled Islands. `ISLAND_HYPRCTL_BIN` overrides monitor discovery in the shortcut adapters.

Run `bash ./island/integration/tests/osd-settings` for isolated Clock/OSD panel loading, saved font and slider settings, monitor routing, fallback labels and stacks, simultaneous events, independent expiry, input validation, and dry-run checks.

Run `bash ./island/integration/tests/clock-settings` for clock alignment during animations and monitor transfers at different font sizes, midnight/noon formatting, actual clock and settings-switch clicks, shared saved format, validation, and dry-run checks.

Control Center shows a labeled brightness slider for every connected monitor, including screens without an Island. External displays use detected DDC/CI buses; internal eDP/LVDS/DSI panels use `brightnessctl`. Unsupported displays remain listed with a disabled slider. The brightness section scrolls when there are more monitors than fit, and writes are coalesced while dragging. Existing DP/HDMI brightness shortcuts and the sliders share their state and locks. `ISLAND_BRIGHTNESS_WRITE_DELAY_MS` sets the write delay (default 150 ms), and `ISLAND_BRIGHTNESS_POLL_MS` sets hardware refresh while the controls are visible (default 5000 ms). `ISLAND_DDCUTIL_BIN` and `ISLAND_BRIGHTNESSCTL_BIN` override the hardware tools.

The Night Light button runs `~/bin/system-toggle-nightlight`, the script currently used by the Hyprland shortcut. It watches `${XDG_RUNTIME_DIR:-/tmp}/system-toggle-nightlight.state` and checks whether `hyprsunset` is running, matching the script's handling of stale state. Override the command with `ISLAND_NIGHTLIGHT_SCRIPT` and its state file with `ISLAND_NIGHTLIGHT_STATE_FILE`.

Run `bash ./island/integration/tests/control-center` for isolated DDC/backlight routing, independent writes, drag coalescing, shortcut synchronization, bounded scrolling, nightlight button/external-script synchronization, stale daemon state, validation, and dry-run checks. Hardware and the nightlight daemon are mocked on a private D-Bus/Xvfb session. Live hardware checks are separate. Island IPC exposes `brightness`, `setBrightness <monitor> <percent>`, `nightlightEnabled`, and `toggleNightlight`.

Workspace changes briefly replace the clock on the active monitor switching workspaces with a workspace display, fading and sliding in both directions. Other monitors keep showing their clock. Settings → Workspaces selects the default label without an icon or dots: the active dot uses the accent and widens, occupied dots use the secondary text color, and empty dots use the surface color. Persistent workspaces are enabled by default and follow Hyprland's persistent workspace rules. Show all monitors is off by default: the dots show only workspaces belonging to Island's monitor; enable it to include every monitor. Disable persistent workspaces to show only occupied workspaces and the active workspace. The workspace count limits persistent slots (1–20, default 11); when no rules are available, it supplies numbered slots. Active and occupied workspaces are included beyond that limit. Dot size is configurable (1–31 px, default 8), capped at 2 px below Island’s compact height. Animation duration is configurable (0–500 ms, default 160). All these options are saved with Island's settings.

Static palettes come from `~/.config/themes/<name>/Colors.qml`, with wallpapers from that theme's `wallpapers` directory. Dynamic wallpapers come from `~/files/pictures/wallpapers/dynamic`. Dynamic uses the existing Material palette engine and desktop renderer, with its own generated output at `~/.config/themes/.dynamic/island`. The application selector and Spicetify link accept Island alongside Caelestia and Noctalia.

Wallpaper previews are generated with Python/Pillow and stored in `~/.cache/island/wallpapers/`. Reopening the gallery retains its loaded images and scroll position. The active theme's wallpaper directory is scanned every two seconds, including nested folders; additions and edits generate only the affected previews. Cache keys include the source path, file timestamps, size, and preview dimensions. Override the location with `ISLAND_THUMBNAIL_CACHE_DIR` and the scan interval with `ISLAND_WALLPAPER_SCAN_INTERVAL`. `scripts/cache-wallpapers.sh --help` documents one-shot, watch, and dry-run modes.

Island remembers its theme, dynamic light/dark mode, palette variant, and wallpaper selection per theme in `~/.local/state/island/`. Caelestia and Noctalia continue using their own saved state. Waybar's named theme is saved on exit and restored on return. Static wallpaper selections in Island do not rewrite a theme's shared `wallpaper.png` link.

Settings lists Appearance, Clock, OSD, Workspaces, Dynamic palette, Notifications, Interaction, and Wallpaper animation as clickable rows with trailing arrows. Each opens its own panel; Back and Escape return to the list. Settings apply automatically: monitor, margin, radius, opacity, space below the always-reserved compact Island, hover/collapse delay, visualizer, dynamic mode/variant, and wallpaper transition/duration/FPS. Wallpaper transitions inherit the other `~/.config/background/bg-set.conf` options. All wallpaper application goes through `awww`; returning to Island restores without animation.

Scrollable panels show a slim accent line beneath the title without changing its position. The line starts at the visible fraction of the content and reaches the title's full width at the bottom. Audio combines progress across its output and input lists. Settings → Interaction → Scroll indicator controls permanent visibility (default on), the duration after opening or scrolling (100–10000 ms, default 1500), full indicators on pages without scrolling (default off), and animation duration (0–1000 ms, default 180). The saved keys are `scrollProgressAlwaysVisible`, `scrollProgressVisibleDuration`, `scrollProgressShowOnNonScrollable`, and `scrollProgressAnimationDuration`.

The indicator follows moving content directly. Mouse-wheel scrolling smoothly combines consecutive steps; touchpad pixel movement follows the gesture directly, and galleries/history do not snap to rows. Settings → Interaction → Scrolling controls smoothing duration (`scrollAnimationDuration`, 0–1000 ms, default 180) and wheel distance (`scrollWheelStep`, 16–200 px, default 64).

Island owns `org.freedesktop.Notifications` while its shell mode is running, so `notify-send` and application notifications use its native popups. Popups share the Island's background, opacity, corner radius, and theme colors. Each begins as a small capsule behind the Island, shoots downward, and expands into its notification card. Island uses the overlay layer above the notification window's top layer so it conceals the emerging fragment. Popups use the focused Island monitor and stay there; if it disappears, they move to an available Island monitor. They follow the Island's bottom edge when its panels expand and reserve no extra desktop space.

Notifications form an overlapping deck with the newest card in front. Up to three cards are visible by default, with older cards peeking out underneath; further cards stay hidden until they reach the front. The deck's height stays bounded regardless of how many notifications arrive. Only the front card accepts input, and dismissing it reveals the next newest notification. Replacements also move to the front.

The notification surface stays mapped as a transparent one-pixel strip with an empty input region while idle. This avoids Hyprland's layer-entry fade concealing the fragment animation. The fragment itself enters fully opaque behind the Island and reveals its content as it expands.

Settings → Notifications saves popup width (`notificationWidth`, default 400 px), starting width as a percentage of the Island (`notificationStartWidthPercent`, 50%), margin below the Island (`notificationMargin`, 10 px), extra downward travel (`notificationSlideDistance`, 24 px), visible cards (`notificationStackVisible`, 3), stack spacing (`notificationStackSpacing`, 8 px), animation duration (`notificationAnimationDuration`, 300 ms), and default timeout (`notificationTimeout`, 5000 ms). Starting width is capped below the final popup width so it always grows. The settled gap is the margin plus the extra slide distance. For example, `./island/integration/island-theme --dry-run setting notificationWidth 480` previews a change; remove `--dry-run` to save it.

Popups support notification artwork with app-icon/bell fallbacks, body markup, links, default actions, action buttons, and dismissal. Hovering pauses the remaining timeout. App-requested timeouts take precedence; zero-timeout notifications and critical notifications without an explicit timeout remain until closed. Replacements update one notification and restart its timeout, including identical replacements. Expired and dismissed notifications remain in the existing in-memory history; transient notifications only show a popup.

Run `bash ./island/integration/tests/notifications` to check settings and dry-run behavior, actual notification delivery on a private D-Bus session, animated geometry, stacking, monitor routing, replacement timing, hover pause, expiry, client closure, actions, and history on an isolated Xvfb display. The test copy omits Wayland layer-shell properties, so it does not validate compositor placement on the live desktop. It requires `dbus-run-session`, `busctl`, `xvfb-run`, `jq`, and Quickshell.

Settings → Appearance → Monitor offers All or a specific monitor. All displays and reserves Island on every connected monitor, including monitors connected later. Expanded panels open on the active monitor and stay on that monitor until closed; changing monitor focus does not move them. Other monitors keep their compact bar. It replaces Automatic and is the default; saved Automatic selections map to All. Workspace dots still follow each Island's monitor unless Show all monitors is enabled.

The switch coordinator stops the previous profile, restores the destination theme and wallpaper, starts the new profile, verifies Island's IPC readiness, and commits the mode markers. Failed startup attempts restore the previous profile. An Island login startup uses Hyprlock; active shell transitions keep the existing close-panel delay and transition lock.

Useful overrides: `ISLAND_STATE_DIR`, `ISLAND_CACHE_DIR`, `ISLAND_DYNAMIC_WALLPAPERS_DIR`, `ISLAND_THEME_SCRIPT`, `ISLAND_THEME_PREWARM`, `ISLAND_QUICKSHELL_CONFIG`, `ISLAND_MODE_FUNCTIONS`, and `WAYBAR_THEME_STATE`. The controller offers `--dry-run` for mutations; see `island/integration/island-theme --help`.

Run `./island/integration/tests/mode-transitions` for the mocked profile matrix and failure rollback, and `./island/integration/tests/theme-state` for isolated real static/dynamic rendering and state restoration. Qt view instantiation and these tests do not replace checking actual rendered shell transitions on the desktop.

Run `bash ./island/integration/tests/workspaces` for saved setting defaults/validation, monitor filtering, persistent and occupied dots, delegate reuse, and interrupted/bidirectional animations in an isolated offscreen Quickshell instance.

Desktop reservation protects the top margin and compact clock height (at least 33 px). `reservedSpaceBelow` controls the visible gap to tiled window borders, accounting for Hyprland's top outer gap. Zero adds no space below the clock. Opening larger panels keeps this reservation stable. Existing `exclusiveZone` settings migrate to this gap when loaded.
