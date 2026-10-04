pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../services"
import "../styles"

Item {
    id: root

    required property NotificationData entry
    property real islandWidth: 160
    property real islandHeight: 33
    property real landingY: 67
    property int stackIndex: 0
    property real stackSpacing: 8
    property real frontHeight: fullHeight
    property real deckDepth: stackIndex
    property bool appeared: false
    property real progress: appeared && entry.popup ? 1 : 0
    readonly property real expansion: Math.max(0, (progress - 0.2) / 0.8)
    readonly property real startWidth: Math.min(width * 0.9, islandWidth * (ThemeService.settings.notificationStartWidthPercent ?? 50) / 100)
    readonly property real startHeight: Math.min(33, islandHeight)
    readonly property real originY: (islandHeight - startHeight) / 2
    readonly property real fullHeight: Math.max(80, content.implicitHeight + 32)
    readonly property alias surface: capsule

    Component.onCompleted: Qt.callLater(() => { root.appeared = true; })
    Behavior on progress {
        NumberAnimation { duration: root.entry.animationDuration; easing.type: Theme.animationVertical }
    }
    Behavior on deckDepth {
        NumberAnimation { duration: root.entry.animationDuration; easing.type: Theme.animationVertical }
    }

    Rectangle {
        id: capsule
        objectName: "notification-capsule"
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.originY + (root.landingY - root.originY) * root.progress + root.deckDepth * root.stackSpacing
        width: root.startWidth + (root.width * (1 - 0.04 * root.deckDepth) - root.startWidth) * root.expansion
        height: root.startHeight + ((root.stackIndex > 0 ? root.frontHeight : root.fullHeight) - root.startHeight) * root.expansion
        radius: ThemeService.settings.radius ?? Theme.capsuleRadius
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b,
            Theme.background.a * (ThemeService.settings.opacity ?? 1))
        opacity: root.entry.popup ? 1 : root.progress
        border.width: root.stackIndex > 0 ? 1 : 0
        border.color: Theme.borderSubtle
        clip: true

        HoverHandler {
            enabled: root.stackIndex === 0
            onHoveredChanged: root.entry.hovered = hovered
        }

        MouseArea {
            enabled: root.stackIndex === 0
            anchors.fill: parent
            cursorShape: root.entry.actions.some(action => action.identifier === "default")
                ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                const action = root.entry.actions.find(action => action.identifier === "default");
                if (action) root.entry.invoke(action);
            }
        }

        ColumnLayout {
            id: content
            x: (parent.width - width) / 2
            y: 16
            width: root.width - 32
            spacing: 8
            visible: root.stackIndex === 0
            opacity: Math.max(0, (root.progress - 0.3) / 0.7)

            RowLayout {
                Layout.fillWidth: true
                spacing: 12
                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 44
                    radius: Theme.radiusMedium
                    color: Theme.surface
                    clip: true
                    Image {
                        id: artwork
                        property bool imageFailed: false
                        property bool iconFailed: false
                        readonly property bool usingBell: (!root.entry.image.toString() || imageFailed)
                            && (iconFailed || root.entry.icon.toString() === NotificationService.defaultIcon.toString())
                        visible: !usingBell
                        anchors.fill: parent
                        anchors.margins: 4
                        source: root.entry.image.toString() && !imageFailed ? root.entry.image
                            : !iconFailed ? root.entry.icon : NotificationService.defaultIcon
                        sourceSize.width: 64
                        sourceSize.height: 64
                        fillMode: Image.PreserveAspectFit
                        onStatusChanged: {
                            if (status !== Image.Error) return;
                            if (root.entry.image.toString() && !imageFailed) imageFailed = true;
                            else iconFailed = true;
                        }
                        Connections {
                            target: root.entry
                            function onImageChanged() { artwork.imageFailed = false; }
                            function onIconChanged() { artwork.iconFailed = false; }
                        }
                    }
                    SvgIcon {
                        anchors.centerIn: parent
                        source: "../assets/icons/bell.svg"
                        color: Theme.icon
                        size: 24
                        visible: artwork.usingBell
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        Layout.fillWidth: true
                        text: root.entry.app || "Notification"
                        textFormat: Text.PlainText
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: root.entry.summary
                        textFormat: Text.PlainText
                        color: Theme.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
                IconButton {
                    iconSource: "../assets/icons/close.svg"
                    description: "Dismiss notification"
                    implicitWidth: 30
                    implicitHeight: 30
                    padding: 7
                    onClicked: root.entry.dismiss()
                }
            }
            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.entry.body
                textFormat: Text.StyledText
                color: Theme.textSecondary
                linkColor: Theme.accent
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
                onLinkActivated: link => Qt.openUrlExternally(link)
            }
            Flow {
                Layout.fillWidth: true
                spacing: 6
                visible: actions.count > 0
                Repeater {
                    id: actions
                    model: root.entry.actions.filter(action => action.identifier !== "default")
                    Button {
                        id: actionButton
                        required property var modelData
                        text: modelData.text
                        padding: 8
                        width: Math.min(implicitWidth, content.width)
                        onClicked: root.entry.invoke(modelData)
                        contentItem: Text {
                            text: actionButton.text
                            color: Theme.textPrimary
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }
                        background: Rectangle {
                            radius: Theme.radiusSmall
                            color: actionButton.down ? Theme.buttonPressed : actionButton.hovered ? Theme.buttonHover : Theme.buttonBackground
                        }
                    }
                }
            }
        }
    }
}
