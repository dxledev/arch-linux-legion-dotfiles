import QtQuick

import "../components"
import "../core"
import "../services"
import "../styles"

FocusScope {
    id: root

    implicitWidth: 550
    implicitHeight: content.implicitHeight + 48

    focus: true

    property alias selectedIndex: themeView.currentIndex
    property int columns: 3

    Component.onCompleted: searchField.forceActiveFocus()

    FilteredListModel {
        id: filteredThemes
        sourceModel: ThemeService.themes
        searchText: searchField.text
        roles: ["themeId", "name", "background", "color1", "color2", "color3", "color4", "accent", "text"]
        searchRoles: ["name", "themeId"]
        onRebuilt: function(resetSelection) {
            root.selectedIndex = model.count > 0 ? (resetSelection ? 0 : Math.max(0, Math.min(root.selectedIndex, model.count - 1))) : -1;
            if (resetSelection) themeView.positionViewAtBeginning();
        }
    }

    function applySelectedTheme() {
        if (!ThemeService.busy && selectedIndex >= 0 && selectedIndex < filteredThemes.model.count)
            ThemeService.apply(filteredThemes.model.get(selectedIndex).themeId);
    }

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: 24

        spacing: 12

        PanelHeader {
            title: "Themes"
            scrollTargets: [themeView]
            trailingText: ThemeService.currentTheme
            trailingClickable: ThemeService.state.source === "dynamic"
            onTrailingClicked: IslandController.openSettingsSection("dynamicPalette")
            onBack: IslandController.openNavigation()
        }

        SearchField {
            id: searchField
            width: parent.width
            placeholderText: "Search themes…"
            onNavigateDown: { focus = false; root.forceActiveFocus(); }
            onAccepted: root.applySelectedTheme()
        }

        GridView {

            id: themeView
            readonly property bool scrollAnimationRunning: wheelScroll.animating
            SmoothScroll { id: wheelScroll; scrollTarget: themeView }

            width: parent.width
            height: cellHeight * 3


            clip: true

            interactive: true

            boundsBehavior: Flickable.StopAtBounds

            cellWidth: width / root.columns
            cellHeight: 96

            model: filteredThemes.model

            currentIndex: 0

            delegate: Item {

                width: themeView.cellWidth
                height: themeView.cellHeight


                ThemeCard {

                    anchors.fill: parent

                    anchors.margins: 8

                    themeId: model.themeId

                    themeName: model.name

                    backgroundColor: model.background

                    color1: model.color1
                    color2: model.color2
                    color3: model.color3
                    color4: model.color4

                    accentColor: model.accent

                    textColor: model.text

                    selected: index === themeView.currentIndex
                }


                MouseArea {

                    anchors.fill: parent
                    enabled: !ThemeService.busy

                    cursorShape: Qt.PointingHandCursor

                    onClicked: {

                        root.selectedIndex = index

                        ThemeService.apply(model.themeId)

                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: filteredThemes.model.count === 0 && searchField.text.length > 0
                text: "No themes match your search."
                color: Theme.textSecondary
                font.pixelSize: 13
            }
        }
        Text {
            width: parent.width
            text: ThemeService.error || (ThemeService.busy ? "Applying…" : "")
            visible: text.length > 0
            color: ThemeService.error ? Theme.danger : Theme.textSecondary
            wrapMode: Text.Wrap
            font.pixelSize: 13
        }
    }

    Keys.onPressed: function(event) {

        if (event.key === Qt.Key_F && (event.modifiers & Qt.ControlModifier)) {
            searchField.forceActiveFocus();
            event.accepted = true;
            return;
        }

        if (searchField.activeFocus && event.key !== Qt.Key_Escape)
            return;

        switch (event.key) {

        case Qt.Key_Left:
        case Qt.Key_H:

            if (selectedIndex % columns > 0)
                selectedIndex--

            event.accepted = true
            break


        case Qt.Key_Right:
        case Qt.Key_L:

            if (selectedIndex % columns < columns - 1 &&
                selectedIndex < filteredThemes.model.count - 1)

                selectedIndex++

            event.accepted = true
            break


        case Qt.Key_Up:
        case Qt.Key_K:

            if (selectedIndex - columns >= 0)
                selectedIndex -= columns

            event.accepted = true
            break


        case Qt.Key_Down:
        case Qt.Key_J:

            if (selectedIndex + columns < filteredThemes.model.count)
                selectedIndex += columns

            event.accepted = true
            break


        case Qt.Key_Return:
        case Qt.Key_Enter:

            root.applySelectedTheme()

            event.accepted = true
            break


        case Qt.Key_Escape:

            IslandController.reset()

            event.accepted = true
            break
        }
    }
}
