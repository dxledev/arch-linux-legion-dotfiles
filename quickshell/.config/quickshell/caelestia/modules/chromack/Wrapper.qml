import QtQuick
import Quickshell
import qs.services

Item {
    id: root
    required property ShellScreen screen
    readonly property bool shouldBeActive: ChromackState.isOpen && ChromackState.screen === screen && !ChromackState.picking
    readonly property bool keyboardFocused: content.item?.activeFocus ?? false
    readonly property bool acquireFocus: focusTimer.running && shouldBeActive
    readonly property real occupiedHeight: height * (1 - offsetScale)
    property real offsetScale: shouldBeActive ? 0 : 1
    implicitWidth: Math.max(1, Math.min(ChromackState.options.width ?? 520, parent.width))
    implicitHeight: Math.max(1, Math.min(ChromackState.options.height ?? (ChromackState.options.heightRatio !== undefined ? parent.height * ChromackState.options.heightRatio : 610), parent.height - 110))
    visible: offsetScale < 1 && ChromackState.screen === screen && !ChromackState.launcherOpen
    opacity: 1 - offsetScale
    anchors.bottomMargin: -(implicitHeight + 5) * offsetScale
    Behavior on offsetScale {
        NumberAnimation {
            duration: ChromackState.options.duration ?? 220
            easing.type: Easing.OutCubic
        }
    }
    onShouldBeActiveChanged: if (shouldBeActive)
        Qt.callLater(focusPanel)
    function focusPanel(): void {
        if (!shouldBeActive)
            return;
        focusTimer.restart();
        if (content.item)
            content.item.forceActiveFocus();
    }
    Timer {
        id: focusTimer
        interval: 100
    }
    Connections {
        target: ChromackState
        function onFocusRequested(): void {
            root.focusPanel();
        }
    }
    Loader {
        id: content
        anchors.fill: parent
        active: root.shouldBeActive || root.visible
        sourceComponent: Content {}
        onLoaded: root.focusPanel()
    }
}
