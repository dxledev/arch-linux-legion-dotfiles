import QtQuick

import "../styles"
import "../core"

Item {
    id: root

    property bool interactive: true

    // Keyboard: Enter or Space opens the media panel, like a tap; the ring shows only for keyboard focus.
    activeFocusOnTab: interactive
    Keys.onReturnPressed: IslandController.openMediaFromLeftSection()
    Keys.onEnterPressed: IslandController.openMediaFromLeftSection()
    Keys.onSpacePressed: IslandController.openMediaFromLeftSection()
    Rectangle {
        anchors.fill: parent
        radius: Theme.capsuleRadius / 2
        color: "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.accent
    }

    implicitWidth: Theme.leftSectionWidth
    implicitHeight: nowPlaying.implicitHeight

    NowPlayingWidget {
        id: nowPlaying

        anchors.left: parent.left
        anchors.leftMargin: Theme.sectionGap
        anchors.verticalCenter: parent.verticalCenter
    }

    HoverHandler {
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.interactive

        acceptedButtons: Qt.LeftButton
        gesturePolicy: TapHandler.ReleaseWithinBounds

        onTapped: function(event) {

            event.accepted = true

            IslandController.openMediaFromLeftSection()
        }
    }
}