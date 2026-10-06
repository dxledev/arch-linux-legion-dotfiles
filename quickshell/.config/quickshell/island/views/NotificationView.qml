import QtQuick
import QtQuick.Layouts
import "../components"
import "../core"
import "../services"
import "../styles"

Item {
    id: root
    implicitHeight: 36 + 12 + 120

    FilteredListModel {
        id: latestNotification
        sourceModel: NotificationService.history
        maximumCount: 1
        roles: ["notificationId", "app", "summary", "body", "icon", "image", "time"]
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            UiText {
                text: "Notifications"
                color: Theme.textPrimary
                font.pixelSize: 16
                font.bold: true
            }
            IconButton {
                objectName: "open-notifications"
                iconSource: "../assets/icons/more-horizontal.svg"
                description: "Show notifications"
                onClicked: IslandController.openNotifications()
            }
            Item { Layout.fillWidth: true }
            IslandButton {
                implicitHeight: 32
                text: "Clear All"
                backgroundColor: Theme.surfaceVariant
                textColor: Theme.textSecondary
                hoverTextColor: Theme.accent
                cursorShape: Qt.PointingHandCursor
                enabled: NotificationService.history.count > 0
                onClicked: NotificationService.clear()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            Repeater {
                model: latestNotification.model
                NotificationCard {
                    required property var model
                    width: parent.width
                    notification: model
                }
            }
            UiText {
                anchors.centerIn: parent
                visible: latestNotification.model.count === 0
                text: "No notifications"
                color: Theme.textSecondary
                font.pixelSize: 14
            }
        }
    }
}
