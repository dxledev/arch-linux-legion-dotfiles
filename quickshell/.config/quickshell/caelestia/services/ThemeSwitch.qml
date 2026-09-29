pragma Singleton

import QtQuick
import Quickshell
import qs.integration
import qs.services

Singleton {
    id: root

    property string pendingThemeId: ""
    property bool pendingDynamic: false
    property bool pendingApplied: false

    function request(themeId: string, dynamic: bool, applied: bool): void {
        pendingThemeId = themeId;
        pendingDynamic = dynamic;
        pendingApplied = applied;
        delay.restart();
    }

    function applyPending(): void {
        if (pendingDynamic) {
            Colours.setSource("dynamic");
        } else if (pendingApplied) {
            Colours.setSource("system");
        } else {
            System.run("theme", [pendingThemeId]);
        }
    }

    Timer {
        id: delay

        interval: 300
        repeat: false
        onTriggered: root.applyPending()
    }
}
