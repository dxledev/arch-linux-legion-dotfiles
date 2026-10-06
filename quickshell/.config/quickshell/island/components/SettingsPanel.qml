import QtQuick
import QtQuick.Controls
import "../core"
import "../services"
import "../styles"

FocusScope {
    id: root
    required property string title
    default property alias content: body.data
    property real contentSpacing: 22
    property real maximumHeight: 650
    property string scrollObjectName: "settings-panel-scroll"
    property var backAction: () => IslandController.openSettings()
    property var escapeAction: backAction
    signal back()
    onBack: root.backAction()
    implicitWidth: 560
    implicitHeight: Math.min(maximumHeight, header.y + header.height + scroll.anchors.topMargin
        + body.implicitHeight + scroll.anchors.bottomMargin + status.implicitHeight + status.anchors.bottomMargin)
    Component.onCompleted: forceActiveFocus()
    Keys.onEscapePressed: root.escapeAction()
    PanelHeader {
        id: header
        x: 24
        y: 20
        width: parent.width - 48
        title: root.title
        scrollTargets: [scroll]
        onBack: root.back()
    }
    Flickable {
        id: scroll
        readonly property bool scrollAnimationRunning: wheelScroll.animating
        objectName: root.scrollObjectName
        anchors.top: header.bottom
        anchors.bottom: status.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        anchors.topMargin: 18
        contentHeight: body.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        SmoothScroll { id: wheelScroll; scrollTarget: scroll }
        Column {
            id: body
            width: parent.width
            spacing: root.contentSpacing
        }
        ScrollBar.vertical: ScrollBar {
            width: 4
            contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.textMuted; opacity: 0.5 }
        }
    }
    UiText {
        id: status
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        text: ThemeService.error || (ThemeService.busy ? "Applying…" : "Saved automatically")
        color: ThemeService.error ? Theme.danger : Theme.textMuted
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font.pixelSize: 11
    }
}
