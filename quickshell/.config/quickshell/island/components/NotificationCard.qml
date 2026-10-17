import QtQuick
import QtQuick.Layouts
import "../services"
import "../styles"

Rectangle {
    id: root
    required property var notification
    implicitHeight: 120
    radius: 16
    color: Theme.surfaceVariant
    clip: true
    readonly property var formattedSummary: NotificationFormat.format(notification.summary)
    readonly property var formattedBody: NotificationFormat.formatLines(notification.body)
    // Buttons of a notification whose sender is still waiting; stored records and answered ones have none.
    readonly property var actions: NotificationService.actionsFor(notification.notificationId)

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            Layout.alignment: Qt.AlignTop
            radius: 12
            color: Theme.surface

            Image {
                id: artwork
                anchors.fill: parent
                anchors.margins: 4
                source: root.notification.image || root.notification.icon
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
            }
            SvgIcon {
                anchors.centerIn: parent
                source: "../assets/icons/bell.svg"
                size: 24
                color: Theme.textSecondary
                visible: artwork.status !== Image.Ready
            }
        }

        ColumnLayout {
            objectName: "notification-card-text"
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                UiText {
                    Layout.fillWidth: true
                    text: root.notification.app
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.bold: true
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                IconButton {
                    implicitWidth: 24
                    implicitHeight: 24
                    padding: 4
                    iconSource: "../assets/icons/close.svg"
                    description: "Dismiss notification"
                    onClicked: NotificationService.removeById(root.notification.notificationId)
                }
            }
            UiText {
                Layout.fillWidth: true
                text: root.formattedSummary.preview
                color: Theme.textPrimary
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                textFormat: Text.StyledText
            }
            UiText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: root.formattedBody.preview
                // Extra air above the second line (e.g. the artist under a track title).
                lineHeight: root.formattedBody.lines > 1 ? 1.35 : 1
                lineHeightMode: Text.ProportionalHeight
                color: Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.Wrap
                textFormat: Text.StyledText
                maximumLineCount: root.actions.length > 0 ? 1 : 2
                elide: Text.ElideRight
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                UiText {
                    text: root.notification.time
                    color: Theme.textMuted
                    font.pixelSize: 11
                }
                Item { Layout.fillWidth: true }
                Repeater {
                    objectName: "notification-actions"
                    model: root.actions
                    TextActionButton {
                        required property var modelData
                        objectName: "notification-action-" + modelData.identifier
                        Layout.maximumWidth: 140
                        implicitHeight: 24
                        padding: 8
                        text: modelData.text
                        onClicked: NotificationService.invokeAction(root.notification.notificationId, modelData.identifier)
                    }
                }
            }
        }
    }
}
