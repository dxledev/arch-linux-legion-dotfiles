pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../core"
import "../island"
import "../services"
import "../styles"

FocusScope {
    id: root

    objectName: "keybinds-view"
    implicitWidth: 620
    implicitHeight: content.implicitHeight + 44
    focus: true
    property bool actionPending: false
    property string actionError: ""
    readonly property bool actionBusy: actionPending || KeybindService.busy
    readonly property string displayError: actionError || String(KeybindService.error ?? "")
    readonly property bool canRetry: displayError.length > 0 && !actionBusy && !KeybindService.loading

    readonly property var visibleEntries: {
        const matches = KeybindService.filteredEntries(search.text)
        return Array.isArray(matches)
            ? matches.filter(entry => typeof entry.description === "string" && entry.description.trim().length > 0)
            : []
    }

    function focusList() {
        if (list.count > 0 && list.currentIndex < 0)
            list.currentIndex = 0
        list.forceActiveFocus()
        if (list.currentIndex >= 0)
            list.positionViewAtIndex(list.currentIndex, ListView.Contain)
    }

    function moveSelection(delta) {
        if (list.count === 0)
            return
        const nextIndex = Math.max(0, Math.min(list.count - 1,
            list.currentIndex < 0 ? 0 : list.currentIndex + delta))
        list.currentIndex = nextIndex
        list.forceActiveFocus()
        list.positionViewAtIndex(nextIndex, ListView.Contain)
    }

    function executeEntry(entry) {
        if (!entry || actionBusy)
            return
        actionError = ""
        actionPending = true
        if (!KeybindService.execute(entry)) {
            actionPending = false
            actionError = String(KeybindService.error ?? "") || "The shortcut could not be started."
        }
    }

    function executeSelected() {
        if (list.currentIndex >= 0)
            executeEntry(visibleEntries[list.currentIndex])
    }

    onVisibleEntriesChanged: {
        list.currentIndex = visibleEntries.length > 0 ? 0 : -1
        list.positionViewAtBeginning()
    }

    Connections {
        target: KeybindService
        function onActionFinished(succeeded, message) {
            if (!root.actionPending)
                return
            root.actionPending = false
            if (succeeded) {
                root.actionError = ""
                if (IslandState.mode === IslandState.keybindsMode)
                    IslandController.reset()
            } else {
                root.actionError = String(message ?? "") || "The shortcut could not be executed."
            }
        }
    }

    Connections {
        target: IslandState
        function onModeChanged() {
            if (IslandState.mode !== IslandState.keybindsMode)
                root.actionPending = false
        }
    }

    Component.onCompleted: {
        KeybindService.refresh()
        Qt.callLater(() => search.forceActiveFocus())
    }

    Keys.onEscapePressed: IslandController.reset()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            search.forceActiveFocus()
            event.accepted = true
        }
    }

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        PanelHeader {
            Layout.fillWidth: true
            title: "Keybinds"
            subtitle: root.actionBusy ? "Running shortcut…" : "Search and run shortcuts"
            trailingText: list.count + (list.count === 1 ? " shortcut" : " shortcuts")
            scrollTargets: [list]
            onBack: IslandController.openNavigation()
        }

        SearchField {
            id: search
            objectName: "keybind-search"
            Layout.fillWidth: true
            placeholderText: "Search keybinds…"
            onNavigateDown: root.focusList()
            Keys.onReturnPressed: root.executeSelected()
            Keys.onEnterPressed: root.executeSelected()
            Keys.onEscapePressed: IslandController.reset()
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.displayError.length > 0

            UiText {
                Layout.fillWidth: true
                text: root.displayError
                color: Theme.danger
                font.pixelSize: 12
                wrapMode: Text.Wrap
            }
            IslandButton {
                text: "Refresh"
                cursorShape: Qt.PointingHandCursor
                visible: root.canRetry
                onClicked: {
                    root.actionError = ""
                    KeybindService.refresh()
                }
            }
        }

        ListView {
            id: list
            objectName: "keybind-list"
            SmoothScroll { scrollTarget: list }
            Layout.fillWidth: true
            Layout.preferredHeight: 360
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            model: root.visibleEntries
            currentIndex: count > 0 ? 0 : -1

            delegate: Item {
                id: row
                required property var modelData
                required property int index

                readonly property bool selected: list.activeFocus && list.currentIndex === index
                readonly property bool hovered: pointer.containsMouse
                width: list.width
                height: 58
                Accessible.role: Accessible.Button
                Accessible.name: modelData.description + ", " + modelData.shortcut

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: row.selected ? Theme.surfaceVariant : row.hovered ? Theme.card : "transparent"
                    border.width: row.selected ? 1 : 0
                    border.color: Theme.accent
                }

                UiText {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: shortcut.left
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.description
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                Rectangle {
                    id: shortcut
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(keyLabel.implicitWidth + 18, list.width * 0.55)
                    height: 30
                    radius: 8
                    color: Theme.inputBackground
                    border.width: 1
                    border.color: Theme.inputBorder

                    UiText {
                        id: keyLabel
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        text: row.modelData.shortcut
                        color: Theme.textSecondary
                        font.family: Theme.iconFont
                        font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    enabled: !root.actionBusy
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        list.currentIndex = row.index
                        root.executeEntry(row.modelData)
                    }
                }
            }

            UiText {
                anchors.centerIn: parent
                width: parent.width - 24
                visible: list.count === 0 && root.displayError.length === 0
                text: KeybindService.loading ? "Loading keybinds…"
                    : search.text.trim() ? "No keybinds match your search."
                    : "No described keybinds are available."
                color: Theme.textSecondary
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            Keys.onDownPressed: function(event) {
                root.moveSelection(1)
                event.accepted = true
            }
            Keys.onUpPressed: function(event) {
                if (currentIndex <= 0) {
                    search.forceActiveFocus()
                    event.accepted = true
                } else {
                    root.moveSelection(-1)
                    event.accepted = true
                }
            }
            Keys.onReturnPressed: root.executeSelected()
            Keys.onEnterPressed: root.executeSelected()
            Keys.onEscapePressed: IslandController.reset()
        }
    }
}
