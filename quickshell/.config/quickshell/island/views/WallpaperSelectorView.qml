import QtQuick
import "../components"
import "../core"
import "../services"
import "../styles"

FocusScope {
    id: root
    implicitWidth: 600
    implicitHeight: 544
    readonly property int columns: 3
    readonly property int visibleRows: 3
    Component.onCompleted: searchField.forceActiveFocus()
    onVisibleChanged: if (visible) searchField.forceActiveFocus()
    FilteredListModel {
        id: filteredWallpapers
        sourceModel: WallpaperService.currentModel
        searchText: searchField.text
        roles: ["path", "thumbnail"]
        searchRoles: ["path"]
        searchFileNames: true
        onRebuilt: function(resetSelection) {
            gallery.currentIndex = model.count > 0 ? (resetSelection ? 0 : Math.max(0, Math.min(gallery.currentIndex, model.count - 1))) : -1;
            if (resetSelection) gallery.positionViewAtBeginning();
        }
    }
    function applySelectedWallpaper() {
        const index = gallery.currentIndex;
        if (!ThemeService.busy && index >= 0 && index < filteredWallpapers.model.count)
            WallpaperService.apply(filteredWallpapers.model.get(index).path);
    }
    Keys.onEscapePressed: IslandController.reset()
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            searchField.forceActiveFocus();
            event.accepted = true;
            return;
        }
        if (searchField.activeFocus) return;
        let index = gallery.currentIndex;
        if (event.key === Qt.Key_H || event.key === Qt.Key_Left) index--;
        else if (event.key === Qt.Key_L || event.key === Qt.Key_Right) index++;
        else if (event.key === Qt.Key_J || event.key === Qt.Key_Down) index += root.columns;
        else if (event.key === Qt.Key_K || event.key === Qt.Key_Up) index -= root.columns;
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.applySelectedWallpaper();
            event.accepted = true;
            return;
        } else return;
        gallery.currentIndex = Math.max(0, Math.min(index, filteredWallpapers.model.count - 1));
        event.accepted = true;
    }
    Column {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 12
        PanelHeader {
            title: "Wallpapers"
            scrollTargets: [gallery]
            onBack: IslandController.openNavigation()
        }
        SearchField {
            id: searchField
            width: parent.width
            placeholderText: "Search wallpapers…"
            onNavigateDown: { focus = false; root.forceActiveFocus(); }
            onAccepted: root.applySelectedWallpaper()
        }
        GridView {
            id: gallery
            readonly property bool scrollAnimationRunning: wheelScroll.animating
            SmoothScroll { id: wheelScroll; scrollTarget: gallery }
            width: parent.width
            height: cellHeight * root.visibleRows
            clip: true
            model: filteredWallpapers.model
            currentIndex: 0
            cellWidth: width / root.columns
            cellHeight: 128
            snapMode: GridView.NoSnap
            boundsBehavior: Flickable.StopAtBounds
            delegate: Item {
                required property int index
                required property string path
                required property string thumbnail
                width: gallery.cellWidth
                height: gallery.cellHeight
                WallpaperCard {
                    id: thumbnail
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 12
                    height: 100
                    imageSource: parent.thumbnail
                    selected: index === gallery.currentIndex || path === ThemeService.wallpaper
                }
                UiText {
                    anchors.top: thumbnail.bottom
                    anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 14
                    text: path.split("/").pop().replace(/^[0-9]+[-_]*/, "").replace(/\.[^.]+$/, "").replace(/[-_]/g, " ")
                    color: path === ThemeService.wallpaper ? Theme.accent : Theme.textSecondary
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.pixelSize: 12
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: !ThemeService.busy
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { gallery.currentIndex = index; WallpaperService.apply(path); }
                }
            }
            UiText {
                anchors.centerIn: parent
                width: parent.width
                visible: filteredWallpapers.model.count === 0
                text: ThemeService.error || (searchField.text.trim() ? "No wallpapers match your search." : "No wallpapers found for this theme.")
                color: ThemeService.error ? Theme.danger : Theme.textSecondary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                font.pixelSize: 13
            }
        }
    }
}
