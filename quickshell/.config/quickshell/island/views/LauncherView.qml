pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import "../components"
import "../core"
import "../services"
import "../styles"

FocusScope {
    id: root
    implicitWidth: 560
    implicitHeight: content.implicitHeight + 48
    readonly property var results: LauncherService.search(searchField.text)
    onResultsChanged: { apps.currentIndex = results.length ? 0 : -1; apps.positionViewAtBeginning(); }
    Component.onCompleted: searchField.forceActiveFocus()

    function moveSelection(offset) {
        apps.currentIndex = Math.max(0, Math.min(results.length - 1, apps.currentIndex + offset));
        apps.positionViewAtIndex(apps.currentIndex, ListView.Contain);
    }

    function launchSelected() {
        if (LauncherService.launch(results[apps.currentIndex])) IslandController.reset();
    }

    Keys.onEscapePressed: IslandController.reset()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            root.moveSelection(event.key === Qt.Key_Up ? -1 : 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.launchSelected();
            event.accepted = true;
        }
    }
    Column {
        id: content
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12
        PanelHeader { title: "Apps"; scrollTargets: [apps]; onBack: IslandController.openNavigation() }
        SearchField {
            id: searchField
            objectName: "launcher-search"
            width: parent.width
            placeholderText: "Search apps…"
            onNavigateDown: root.moveSelection(1)
            Keys.onUpPressed: root.moveSelection(-1)
            onAccepted: root.launchSelected()
        }
        Row {
            width: parent.width
            spacing: 12
            SettingToggle { width: parent.width - 48; text: "Show all apps"; setting: "launcherShowAllApps" }
            IconButton {
                iconSource: "../assets/icons/settings.svg"
                description: "Launcher settings"
                onClicked: IslandController.openSettingsSection("launcher")
            }
        }
        ListView {
            id: apps
            objectName: "launcher-results"
            width: parent.width
            height: 340
            clip: true
            model: root.results
            currentIndex: root.results.length ? 0 : -1
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            SmoothScroll { scrollTarget: apps }
            ScrollBar.vertical: ScrollBar {}
            delegate: ItemDelegate {
                id: row
                required property var modelData
                required property int index
                width: apps.width
                height: 54
                highlighted: apps.currentIndex === index
                onClicked: { apps.currentIndex = index; root.launchSelected(); }
                background: Rectangle { radius: 12; color: row.highlighted || row.hovered ? Theme.surfaceVariant : "transparent" }
                contentItem: Row {
                    spacing: 12
                    Item {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32; height: 32
                        Image {
                            id: appIcon
                            anchors.fill: parent
                            source: row.modelData.icon.startsWith("/") ? "file:" + row.modelData.icon
                                : Quickshell.hasThemeIcon(row.modelData.icon) ? Quickshell.iconPath(row.modelData.icon) : ""
                            sourceSize.width: 32; sourceSize.height: 32
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                        }
                        SvgIcon {
                            anchors.centerIn: parent
                            source: "../assets/icons/apps.svg"
                            size: 28
                            visible: appIcon.status !== Image.Ready
                        }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 44
                        spacing: 3
                        Text { width: parent.width; text: row.modelData.name; color: Theme.textPrimary; font.pixelSize: 14; elide: Text.ElideRight }
                        Text { width: parent.width; text: row.modelData.description; visible: text.length > 0; color: Theme.textMuted; font.pixelSize: 11; elide: Text.ElideRight }
                    }
                }
            }
            Text {
                anchors.centerIn: parent
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                visible: root.results.length === 0
                text: LauncherService.loading ? "Loading apps…" : (!(ThemeService.settings.launcherShowAllApps ?? true) && LauncherService.error)
                    ? LauncherService.error : "No apps found."
                color: Theme.textMuted
                font.pixelSize: 13
            }
        }
        Text { text: "↑ ↓ Select    Enter Launch    Esc Close"; color: Theme.textMuted; font.pixelSize: 11 }
    }
}
