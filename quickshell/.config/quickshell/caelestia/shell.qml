//@ pragma Env QS_CRASHREPORT_URL=https://github.com/caelestia-dots/shell/issues/new?template=crash.yml
//@ pragma DefaultEnv QS_NO_RELOAD_POPUP=1
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
//@ pragma DefaultEnv QML_IMPORT_PATH=/home/dxle/.config/quickshell/.runtime/qml
//@ pragma DefaultEnv CAELESTIA_LIB_DIR=/home/dxle/.config/quickshell/.runtime/lib/caelestia
//@ pragma DefaultEnv QS_ICON_THEME=Papirus

import "modules"
import "modules/drawers"
import "modules/background"
import "modules/areapicker"
import "modules/lock"
import QtQuick
import Quickshell
import qs.services
import qs.integration

ShellRoot {
    id: root

    settings.watchFiles: false

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root
    }

    GSFLoader {}
    Desktop {}
    ServiceLoader {}

    Background {}
    Drawers {}
    AreaPicker {}
    Shortcuts {}
    BatteryMonitor {}
}
