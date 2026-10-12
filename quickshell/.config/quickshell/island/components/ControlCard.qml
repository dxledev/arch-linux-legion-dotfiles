import QtQuick
import QtQuick.Controls

import "../styles"

Rectangle {
    id: root

    property string icon: ""
    property url iconSource: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool iconEnabled: true
    property bool panelEnabled: false

    signal clicked()
    signal iconToggled()

    implicitWidth: 150
    implicitHeight: 60

    radius: 24
    color: panelButton.down
        ? Theme.buttonPressed
        : panelButton.hovered && !iconButton.hovered
            ? Theme.surfaceVariant
            : Theme.surface
    border.width: panelButton.activeFocus ? 2 : 0
    border.color: Theme.accent
    Behavior on color { ColorAnimation { duration: Theme.animationFast } }

    Button {
        id: panelButton
        objectName: "control-card-navigation"

        anchors.fill: parent
        padding: 0
        enabled: root.panelEnabled
        hoverEnabled: true
        focusPolicy: Qt.TabFocus

        Accessible.name: "Open " + root.title
        Accessible.description: root.subtitle

        contentItem: Item {}

        background: Rectangle {
            color: "transparent"
            radius: root.radius
        }

        containmentMask: QtObject {
            function contains(pt: point): bool {
                const iconCenter = iconButton.mapToItem(panelButton, iconButton.width / 2, iconButton.height / 2);
                const dx = pt.x - iconCenter.x;
                const dy = pt.y - iconCenter.y;
                const radius = iconButton.width / 2;

                return dx * dx + dy * dy > radius * radius;
            }
        }

        HoverHandler {
            enabled: panelButton.enabled && panelButton.hovered
            cursorShape: Qt.PointingHandCursor
        }

        onClicked: root.clicked()
    }

    Row {
        z: 1
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Button {
            id: iconButton
            objectName: "control-card-toggle"

            width: 36
            height: 36
            padding: 0
            enabled: root.iconEnabled
            hoverEnabled: true
            focusPolicy: Qt.TabFocus
            opacity: enabled ? 1 : 0.5

            Accessible.name: "Toggle " + root.title
            Accessible.description: root.subtitle
            Accessible.checkable: true
            Accessible.checked: root.active

            containmentMask: QtObject {
                function contains(pt: point): bool {
                    const dx = pt.x - iconButton.width / 2;
                    const dy = pt.y - iconButton.height / 2;
                    const radius = iconButton.width / 2;

                    return dx * dx + dy * dy <= radius * radius;
                }
            }

            contentItem: Item {
                SvgIcon {
                    anchors.centerIn: parent
                    visible: !!root.iconSource
                    source: root.iconSource
                    size: 18
                    color: root.active ? Theme.background : Theme.textPrimary
                }

                Text {
                    anchors.centerIn: parent
                    visible: !root.iconSource
                    text: root.icon
                    font.family: Theme.iconFont
                    font.pixelSize: 18
                    color: root.active ? Theme.background : Theme.textPrimary
                }
            }

            background: Rectangle {
                radius: width / 2
                color: iconButton.down
                    ? root.active ? Theme.accentPressed : Theme.buttonPressed
                    : root.active
                        ? iconButton.hovered ? Theme.accentHover : Theme.accent
                        : iconButton.hovered ? Theme.surfaceVariant : Theme.buttonBackground
                border.width: iconButton.activeFocus ? 2 : iconButton.hovered ? 1 : 0
                border.color: iconButton.activeFocus ? Theme.textPrimary : root.active ? Theme.background : Theme.accent
                Behavior on color { ColorAnimation { duration: Theme.animationFast } }
            }

            HoverHandler {
                enabled: iconButton.enabled && iconButton.hovered
                cursorShape: Qt.PointingHandCursor
            }

            onClicked: root.iconToggled()
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.top: parent.top
            anchors.topMargin: 1
            spacing: 2
            width: parent.width - iconButton.width - parent.spacing

            UiText {
                width: parent.width
                text: root.title
                color: Theme.textPrimary
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            UiText {
                width: parent.width
                text: root.subtitle
                color: Theme.textSecondary
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }
    }

}
