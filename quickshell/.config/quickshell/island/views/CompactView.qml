import QtQuick
import Quickshell
import "../core"
import "../services"

Item {
    id: root
    anchors.alignWhenCentered: false

    property bool monitorActive: true
    property string monitorName: (QsWindow.window as QsWindow)?.screen?.name ?? ""
    readonly property bool showingStatus: StatusManager.visible && StatusManager.isTargetScreen(monitorName)
        && (StatusManager.mode !== "workspace" || monitorActive)
    readonly property int transitionDuration: StatusManager.mode === "workspace"
        ? (ThemeService.settings.workspaceAnimationDuration ?? 160) : StatusManager.animationDuration
    implicitWidth: showingStatus ? overlay.implicitWidth : clock.implicitWidth
    implicitHeight: Math.max(IslandGeometry.compactHeight, showingStatus ? overlay.implicitHeight : 0)

    DefaultView {
        id: clock
        objectName: "compact-clock"
        anchors.centerIn: parent
        anchors.alignWhenCentered: false
        width: implicitWidth
        height: implicitHeight
        opacity: root.showingStatus ? 0 : 1
        visible: opacity > 0
        transform: Translate {
            y: root.showingStatus ? -6 : 0
            Behavior on y { NumberAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic } }
    }

    OverlayView {
        id: overlay
        monitorName: root.monitorName
        objectName: "compact-status"
        anchors.centerIn: parent
        width: implicitWidth
        height: implicitHeight
        opacity: root.showingStatus ? 1 : 0
        visible: opacity > 0 && StatusManager.isTargetScreen(root.monitorName)
        transform: Translate {
            y: root.showingStatus ? 0 : 6
            Behavior on y { NumberAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic } }
    }
}
