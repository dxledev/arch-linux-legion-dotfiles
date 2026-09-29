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
    property var modeRows: []

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}shell-mode `.length);
    }

    function reload(): void {
        if (getMode.running) {
            refreshPending = true;
            return;
        }

        root.modeRows = [{ id: "loading", name: "Reading active shell...", icon: "sync", error: true }];
        getMode.running = true;
    }

    function loadRows(exitCode: int): void {
        const current = getMode.stdout.text.trim();
        if (exitCode !== 0 || !["waybar", "caelestia", "noctalia"].includes(current)) {
            root.modeRows = [{
                id: "error",
                name: "Could not read active shell",
                description: "toggle-shell-mode --status failed",
                icon: "error",
                error: true
            }];
        } else {
            root.modeRows = [
                { id: "waybar", name: "Waybar", icon: "view_compact", mode: "waybar", active: current === "waybar" },
                { id: "caelestia", name: "Caelestia", icon: "widgets", mode: "caelestia", active: current === "caelestia" },
                { id: "noctalia", name: "Noctalia", icon: "dashboard", mode: "noctalia", active: current === "noctalia" }
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
        model: root.modeRows.map(mode => mode.id)
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
        required property string modelData
        readonly property var row: root.modeRows.find(mode => mode.id === modelData) ?? ({})
        readonly property string name: row.name ?? ""
        readonly property string desc: row.active ? "Active shell" : (row.description ?? "")
        readonly property string icon: row.icon ?? ""

        function onClicked(list: AppList): void {
            if (row.error)
                return;

            list.screenState.launcher = false;
            if (!row.active)
                Quickshell.execDetached([root.modeScript, `--${row.mode}`]);
        }
    }
}
