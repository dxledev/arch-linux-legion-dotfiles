pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../styles"

ColumnLayout {
    id: root

    required property string title
    required property var devices
    required property var currentDevice
    required property url iconSource
    property int maximumListHeight: 180
    property real selectionBorderWidth: 2
    readonly property alias scrollTarget: list
    signal selected(var device)
    spacing: 8

    Text {
        text: root.title
        color: Theme.textPrimary
        font.pixelSize: 16
        font.bold: true
    }

    ListView {
        id: list
        readonly property bool scrollAnimationRunning: wheelScroll.animating
        objectName: root.objectName + "-list"
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(root.maximumListHeight, Math.max(54, contentHeight))
        model: root.devices
        spacing: 8
        clip: true
        SmoothScroll { id: wheelScroll; scrollTarget: list }
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        delegate: Button {
            id: deviceButton
            required property var modelData
            readonly property bool selected: modelData.id === root.currentDevice?.id
            readonly property string deviceLabel: modelData.description || modelData.name || "Unknown device"
            x: 1
            width: list.width - 2
            height: 54
            padding: 12
            hoverEnabled: true
            Accessible.name: deviceLabel + (selected ? ", selected" : "")
            onClicked: root.selected(modelData)

            contentItem: RowLayout {
                spacing: 12
                SvgIcon {
                    source: root.iconSource
                    size: 20
                    color: deviceButton.selected ? Theme.accent : Theme.textSecondary
                }
                Text {
                    Layout.fillWidth: true
                    text: deviceButton.deviceLabel
                    elide: Text.ElideRight
                    font.pixelSize: 13
                    color: Theme.textPrimary
                }
                Text {
                    visible: deviceButton.selected
                    text: "Selected"
                    font.pixelSize: 12
                    color: Theme.accent
                }
            }

            background: Rectangle {
                id: deviceBackground
                readonly property real outlineWidth: deviceButton.selected || deviceButton.activeFocus ? root.selectionBorderWidth : 0
                readonly property color fillColor: deviceButton.down ? Theme.buttonPressed : deviceButton.hovered ? Theme.surfaceVariant : Theme.surface
                radius: 16
                antialiasing: true
                color: outlineWidth > 0 ? Theme.accent : fillColor

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: deviceBackground.outlineWidth
                    radius: Math.max(0, deviceBackground.radius - deviceBackground.outlineWidth)
                    antialiasing: true
                    color: deviceBackground.fillColor
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: list.count === 0
            text: "No devices available"
            color: Theme.textSecondary
            font.pixelSize: 13
        }
    }
}
