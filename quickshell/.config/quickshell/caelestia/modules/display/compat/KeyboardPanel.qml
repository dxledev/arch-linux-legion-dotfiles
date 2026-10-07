import QtQuick
import Quickshell
import Caelestia.Config
import qs.services

FloatingWindow {
    id: root

    default property alias panelData: content.data
    property var anchorItem: null
    property var owner: null
    property var bar: null
    property bool open: false
    property bool centerOnBar: false
    property Item focusTarget: null
    property real contentWidth: 1100
    property real contentHeight: 720
    property real padding: Style.space(16)
    property var borderSpec: Border.none()
    readonly property real availableCardWidth: Math.max(400, (screen?.width ?? 1920) - Style.space(64))
    readonly property real availableCardHeight: Math.max(320, (screen?.height ?? 1080) - Style.space(64))
    readonly property real verticalContentInset: padding * 2

    signal closeRequested()

    function fittedContentWidth(value: real): real {
        return Math.min(availableCardWidth, Math.max(400, value));
    }

    function fittedContentHeight(value: real): real {
        return Math.min(availableCardHeight, Math.max(320, value));
    }

    function activate(): void {
        const client = Hypr.toplevels.values.find(t => t.title === root.title);
        if (client?.address)
            Hypr.dispatch(Hypr.usingLua
                ? `hl.dsp.focus({ window = "address:0x${client.address}" })`
                : `focuswindow address:0x${client.address}`);
        root.contentItem.window?.requestActivate();
        root.focusTarget?.forceActiveFocus();
    }

    title: "Display — Layout Editor"
    visible: open
    color: Color.background
    implicitWidth: contentWidth
    implicitHeight: contentHeight + verticalContentInset
    minimumSize: Qt.size(400, 320)
    contentItem.Config.screen: screen?.name ?? ""
    contentItem.Tokens.screen: screen?.name ?? ""
    onClosed: closeRequested()
    onVisibleChanged: if (visible) Qt.callLater(activate)

    property Item panelContent: Item {
        id: content

        parent: root.contentItem
        anchors.fill: parent
        anchors.margins: root.padding

        Rectangle {
            anchors.fill: parent
            color: Color.background
            z: -1
        }
    }
}
