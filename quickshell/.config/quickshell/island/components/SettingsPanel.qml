import QtQuick
import QtQuick.Controls
import "../core"
import "../services"
import "../styles"
import "." as Local

FocusScope {
    id: root
    required property string title
    default property alias content: body.data
    property real contentSpacing: 22
    property real maximumHeight: 650
    property string scrollObjectName: "settings-panel-scroll"
    property var backAction: () => IslandController.openSettings()
    property var escapeAction: backAction
    // Opt-in search: the header gets a search button and '/' or Ctrl+F reveals a field above the list.
    property bool searchable: false
    property bool searchVisible: false
    property real minimumHeight: 0
    property string searchPlaceholder: "Search…"
    readonly property alias searchInput: searchField
    readonly property alias searchText: searchField.text
    signal back()
    signal searchAccepted()
    signal searchNavigateDown()
    onBack: root.backAction()
    implicitWidth: 560
    // Report the target height so the Island animates once while the search row reveals in step.
    implicitHeight: Math.min(maximumHeight, Math.max(minimumHeight, header.y + header.height + searchReveal.targetHeight
        + scroll.anchors.topMargin + body.implicitHeight + scroll.anchors.bottomMargin
        + status.implicitHeight + status.anchors.bottomMargin))
    Component.onCompleted: forceActiveFocus()

    function toggleSearch() {
        if (!searchable) return;
        searchVisible = !searchVisible;
        if (searchVisible) searchField.forceActiveFocus();
        else {
            searchField.clear();
            searchField.focus = false;
            root.forceActiveFocus();
        }
    }

    function handleSearchToggle(event) {
        if (!searchable || event.key !== Qt.Key_Slash || event.modifiers !== Qt.NoModifier) return false;
        toggleSearch();
        event.accepted = true;
        return true;
    }

    // One handler owns Escape: Qt runs a specific Keys.onEscapePressed before Keys.onPressed.
    Keys.onPressed: function(event) {
        if (searchable && handleSearchToggle(event)) return;
        if (searchable && event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            if (!searchVisible) toggleSearch();
            else searchField.forceActiveFocus();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            if (searchVisible) toggleSearch();
            else root.escapeAction();
            event.accepted = true;
        }
    }
    PanelHeader {
        id: header
        x: 24
        y: 20
        width: parent.width - 48
        title: root.title
        titleActionIcon: root.searchable ? "../assets/icons/search.svg" : ""
        titleActionDescription: root.searchVisible ? "Hide search" : "Search settings"
        titleActionActive: root.searchVisible
        scrollTargets: [scroll]
        onTitleActionClicked: root.toggleSearch()
        onBack: root.back()
    }
    Item {
        id: searchReveal
        readonly property real targetHeight: root.searchVisible ? 18 + searchField.implicitHeight : 0
        // Overhang the clip so fractional panel positions cannot shave the field's side borders.
        x: 22
        width: parent.width - 44
        anchors.top: header.bottom
        height: targetHeight
        clip: true
        visible: root.searchVisible || height > 0
        Behavior on height {
            NumberAnimation {
                duration: ThemeService.settings.islandAnimationDuration ?? 300
                easing.type: Theme.animationVertical
            }
        }
        // Qualified because newer Qt ships its own QtQuick.Controls SearchField.
        Local.SearchField {
            id: searchField
            objectName: "settings-search"
            x: 2
            y: 18
            width: parent.width - 4
            opacity: searchReveal.targetHeight > 0 ? Math.min(1, searchReveal.height / searchReveal.targetHeight) : 0
            placeholderText: root.searchPlaceholder
            onNavigateDown: root.searchNavigateDown()
            onAccepted: root.searchAccepted()
            Keys.onPressed: event => root.handleSearchToggle(event)
        }
    }
    Flickable {
        id: scroll
        readonly property bool scrollAnimationRunning: wheelScroll.animating
        objectName: root.scrollObjectName
        anchors.top: searchReveal.bottom
        anchors.bottom: status.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        anchors.topMargin: 18
        contentHeight: body.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        SmoothScroll { id: wheelScroll; scrollTarget: scroll }
        Column {
            id: body
            width: parent.width
            spacing: root.contentSpacing
        }
        ScrollBar.vertical: ScrollBar {
            width: 4
            contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.textMuted; opacity: 0.5 }
        }
    }
    UiText {
        id: status
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        text: ThemeService.error || (ThemeService.busy ? "Applying…" : "Saved automatically")
        color: ThemeService.error ? Theme.danger : Theme.textMuted
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font.pixelSize: 11
    }
}
