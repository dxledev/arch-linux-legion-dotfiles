pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.launcher.services
import qs.modules.chromack as Chromack

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property var panels

    readonly property bool shouldBeActive: screenState.launcher && Config.launcher.enabled

    readonly property real maxHeight: {
        let max = screen.height - Config.border.thickness * 2 + Tokens.padding.extraLarge;
        if (screenState.dashboard)
            max -= panels.dashboard.nonAnimHeight;
        return max;
    }

    property real offsetScale: shouldBeActive ? 0 : 1
    property var pendingSubmenu: null

    function openSubmenu(submenu: string): void {
        pendingSubmenu = submenu;
        screenState.launcher = true;
        applyPendingSubmenu();
    }

    function applyPendingSubmenu(): void {
        if (content.item && pendingSubmenu !== null) {
            content.item.openSubmenu(pendingSubmenu);
            pendingSubmenu = null;
        }
    }

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            if (Chromack.ChromackState.isOpen)
                Chromack.ChromackState.close(false);
            implicitHeight = Qt.binding(() => content.implicitHeight);
        }
        else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    visible: offsetScale < 1 && !Chromack.ChromackState.isOpen
    anchors.bottomMargin: (-implicitHeight - 5) * offsetScale
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 630 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Component.onCompleted: Qt.callLater(() => {
        Apps;
        Themes;
    })

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        active: root.shouldBeActive || root.visible
        onLoaded: root.applyPendingSubmenu()

        sourceComponent: Content {
            initialSubmenu: root.pendingSubmenu
            screenState: root.screenState
            panels: root.panels
            maxHeight: root.maxHeight
        }
    }
}
