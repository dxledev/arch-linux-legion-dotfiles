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
                text: root.notification.summary
                color: Theme.textPrimary
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
            UiText {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: root.notification.body
                color: Theme.textSecondary
                font.pixelSize: 12
                wrapMode: Text.Wrap
                textFormat: Text.StyledText
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            UiText {
                text: root.notification.time
                color: Theme.textMuted
                font.pixelSize: 11
            }
        }
    }
}
