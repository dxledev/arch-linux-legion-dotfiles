import QtQuick
import "../core"
import "../services"
import "../views"

Item {
    id: root
    objectName: "expanded-status-drawer"

    property bool active: false
    property bool opened: false
    property string monitorName: ""
    property real contentWidth: implicitWidth
    readonly property real contentScale: Math.min(1, contentWidth / Math.max(1, content.implicitWidth))
    property real reveal: opened ? 1 : 0
    readonly property int animationDuration: StatusManager.mode === "workspace"
        ? ThemeService.settings.workspaceAnimationDuration ?? 160 : StatusManager.animationDuration
    implicitWidth: content.implicitWidth
    implicitHeight: active ? reveal * (content.implicitHeight * contentScale + 8) : 0
    visible: height > 0
    clip: true

    Behavior on reveal {
        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    Loader {
        id: content
        active: root.active
        anchors.horizontalCenter: parent.horizontalCenter
        y: 4 - (1 - root.reveal) * implicitHeight * root.contentScale
        scale: root.contentScale
        transformOrigin: Item.Top
        opacity: root.reveal
        visible: StatusManager.isTargetScreen(root.monitorName)
        width: item?.implicitWidth ?? 0
        height: item?.implicitHeight ?? 0
        sourceComponent: OverlayView { monitorName: root.monitorName }
    }
}
