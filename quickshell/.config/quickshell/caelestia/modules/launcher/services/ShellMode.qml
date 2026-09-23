pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

Searcher {
    id: root

    readonly property string modeScript: Quickshell.env("SHELL_MODE_SCRIPT") || `${Quickshell.env("HOME")}/bin/toggle-shell-mode`
    property bool refreshPending: false

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}shell-mode `.length);
    }

    function reload(): void {
        if (getMode.running) {
            refreshPending = true;
            return;
        }

        modes.model = [{ name: "Reading active shell...", icon: "sync", error: true }];
        getMode.running = true;
    }

    function loadRows(exitCode: int): void {
        const current = getMode.stdout.text.trim();
        if (exitCode !== 0 || !["waybar", "caelestia", "noctalia"].includes(current)) {
            modes.model = [{
                name: "Could not read active shell",
                description: "toggle-shell-mode --status failed",
                icon: "error",
                error: true
            }];
        } else {
            modes.model = [
                { name: "Waybar", icon: "view_compact", mode: "waybar", active: current === "waybar" },
                { name: "Caelestia", icon: "widgets", mode: "caelestia", active: current === "caelestia" },
                { name: "Noctalia", icon: "dashboard", mode: "noctalia", active: current === "noctalia" }
            ];
        }

        if (refreshPending) {
            refreshPending = false;
            reload();
        }
    }

    list: modes.instances
    useFuzzy: GlobalConfig.launcher.useFuzzy.schemes

    Variants {
        id: modes
        Mode {}
    }

    Process {
        id: getMode

        command: [root.modeScript, "--status"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: exitCode => root.loadRows(exitCode)
    }

    component Mode: QtObject {
        required property var modelData
        readonly property string name: modelData.name
        readonly property string desc: modelData.active ? "Active shell" : (modelData.description ?? "")
        readonly property string icon: modelData.icon

        function onClicked(list: AppList): void {
            if (modelData.error)
                return;

            list.screenState.launcher = false;
            if (!modelData.active)
                Quickshell.execDetached([root.modeScript, `--${modelData.mode}`]);
        }
    }
}
