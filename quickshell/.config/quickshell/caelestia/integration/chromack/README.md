# Chromack integration

The QML module `Shell.Chromack` provides `ChromackModel` to the panel under `modules/chromack`. Configuration and CSS parsing were copied from `/home/dxle/builds/chromack/src/ChromackConfig.{cpp,h}` on 2026-09-11; `color-functions.h` retains the color helpers from `ChromackPanel.cpp`. The Widgets UI, LayerShellQt placement, D-Bus control, notification server, and standalone state file are not used.

`ChromackModel.state` exposes the active color, CSS style variables, material/recent swatches, generated palette, shade scales, and theory schemes. Mutations use `selectMaterial`, `setColor`, `setHsv`, and `generate`; persistence uses `flush` and `savePalette`. `copy` updates the Wayland clipboard and recent colors. File errors emit `error` for the panel to display. Configuration loading does not create or migrate standalone config files.

Hex input preserves Qt's `#AARRGGBB` convention. Palette TOML exports use `#RRGGBBAA`. Preserve that distinction when changing the port. The generated palette has foreground/background plus 24 numbered colors. Shade and theory swatches copy their value; material swatches select an editable color slot.

Build and test with `scripts/build-chromack`. Tests use temporary configuration and persistence paths. Rebuild this module after Qt ABI upgrades.
