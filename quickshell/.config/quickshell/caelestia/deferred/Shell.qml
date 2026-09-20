pragma ComponentBehavior: Bound

import "../modules" as Modules
import "../modules/areapicker" as AreaPickerModule
import "../modules/background" as BackgroundModule
import "../modules/drawers" as DrawersModule
import QtQuick
import Quickshell
import qs.integration
import qs.services

Scope {
    id: root

    required property var lock
    required property var shellRoot
    property bool startupAetherSyncPending: Quickshell.env("CAELESTIA_START_LOCKED") === "1"

    function syncStartupAether(): void {
        if (!startupAetherSyncPending || Colours.source !== "dynamic" || Colours.provider !== "caelestia")
            return;

        startupAetherSyncPending = false;
        Colours.queueAetherSync();
    }

    Binding {
        target: ShellState
        property: "shellRoot"
        value: root.shellRoot
    }

    Modules.GSFLoader {}
    Desktop {}
    Modules.ServiceLoader {}
    BackgroundModule.Background {}
    DrawersModule.Drawers {}
    AreaPickerModule.AreaPicker {}
    Modules.Shortcuts {}
    Modules.BatteryMonitor {}

    Modules.IdleMonitors {
        lock: root.lock
    }

    Connections {
        function onLockedChanged(): void {
            if (!root.lock.lock.locked)
                root.syncStartupAether();
        }

        target: root.lock.lock
    }

    Component.onCompleted: {
        if (!root.lock.lock.locked)
            root.syncStartupAether();
    }
}
