import QtQuick
import Quickshell
import Caelestia.Config

Item {
    id: root

    required property ShellScreen screen
    readonly property bool shouldBeActive: ClipboardState.isOpen && ClipboardState.screen === screen
    readonly property bool acquireFocus: focusTimer.running && shouldBeActive
    readonly property real occupiedHeight: height * (1 - offsetScale)
    readonly property bool confirmationVisible: content.item?.clearConfirmationOpen ?? false
    readonly property real confirmationHeight: confirmationVisible ? content.item?.confirmationHeight ?? 0 : 0
    property real offsetScale: shouldBeActive ? 0 : 1

    implicitWidth: Math.max(1, Math.min(ClipboardState.options.width ?? 520, parent.width - Tokens.padding.large * 2))
    implicitHeight: Math.max(1, Math.min(ClipboardState.options.height ?? 610, parent.height - 100))
    visible: offsetScale < 1 && ClipboardState.screen === screen
    opacity: 1 - offsetScale
    anchors.bottomMargin: -(implicitHeight + 5) * offsetScale

    Behavior on offsetScale {
        NumberAnimation {
            duration: ClipboardState.options.durationMs ?? 220
            easing.type: Easing.OutCubic
        }
    }

    function focusPanel(): void {
        if (!shouldBeActive)
            return;
        focusTimer.restart();
    }

    onShouldBeActiveChanged: if (shouldBeActive) Qt.callLater(focusPanel)

    Timer {
        id: focusTimer
        interval: 100
    }

    Connections {
        target: ClipboardState
        function onFocusRequested(): void {
            root.focusPanel();
        }
        function onOpeningIdChanged(): void {
            if (root.shouldBeActive)
                Qt.callLater(root.focusPanel);
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
