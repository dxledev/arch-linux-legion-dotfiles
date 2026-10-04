import QtQuick
import QtQuick.Layouts
import "../components"
import "../core"
import "../services"
import "../styles"

FocusScope {
    id: root
    implicitWidth: 520
    implicitHeight: content.implicitHeight + 44
    focus: true

    FilteredListModel {
        id: filteredNotifications
        sourceModel: NotificationService.history
        searchText: search.text
        roles: ["notificationId", "app", "summary", "body", "icon", "image", "time"]
        searchRoles: ["app", "summary", "body"]
        onRebuilt: resetSelection => { if (resetSelection) list.positionViewAtBeginning(); }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        PanelHeader {
            Layout.fillWidth: true
            title: "Notifications"
            scrollTargets: [list]
            onBack: IslandController.openControlCenter()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            SvgIcon {
                source: "../assets/icons/bell.svg"
                size: 20
                color: Theme.textPrimary
            }
            Text {
                objectName: "notification-count"
                text: NotificationService.history.count > 99 ? "99+" : String(NotificationService.history.count)
                color: Theme.textPrimary
                font.pixelSize: 14
                Accessible.name: NotificationService.history.count + " notifications"
            }
            Item { Layout.fillWidth: true }
            IslandButton {
                text: "Clear All"
                cursorShape: Qt.PointingHandCursor
                enabled: NotificationService.history.count > 0
                onClicked: NotificationService.clear()
            }
        }

        SearchField {
            id: search
            objectName: "notification-search"
            Layout.fillWidth: true
            placeholderText: "Search notifications…"
            onNavigateDown: list.forceActiveFocus()
        }

        ListView {
            id: list
            readonly property bool scrollAnimationRunning: wheelScroll.animating
            SmoothScroll { id: wheelScroll; scrollTarget: list }
            objectName: "notification-list"
            Layout.fillWidth: true
            Layout.preferredHeight: 3 * 120 + 2 * spacing
            spacing: 10
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            snapMode: ListView.NoSnap
            model: filteredNotifications.model
            delegate: NotificationCard {
                required property var model
                width: list.width
                notification: model
            }
            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: search.text.trim() ? "No matching notifications" : "No notifications"
                color: Theme.textSecondary
                font.pixelSize: 14
            }
        }
    }

    Component.onCompleted: search.forceActiveFocus()
    Keys.onEscapePressed: IslandController.reset()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            search.forceActiveFocus()
            event.accepted = true
        }
    }
}
