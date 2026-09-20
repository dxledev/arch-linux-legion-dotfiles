pragma Singleton

import QtQuick
import Quickshell
import qs.utils

Singleton {
    id: root

    readonly property string workspaceControlScript: `${Paths.home}/bin/hypr-toggle-workspace-control`
    readonly property string missionControlScript: `${Paths.home}/bin/hypr-toggle-mission-control`

    function showOverview(): void {
        Quickshell.execDetached([root.workspaceControlScript]);
    }

    function showMissionControl(): void {
        Quickshell.execDetached([root.missionControlScript]);
    }
}
