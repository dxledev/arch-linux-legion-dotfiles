import QtQuick
import QtQuick.Effects
import Quickshell.Widgets

import "../island"
import "../services"
import "../styles"

// Floating lyrics card. Enters exactly like a notification card (grows out of the island, slides
// to its landing spot) but is not a notification: it stays until its own close button is used.
Item {
    id: root

    property real islandWidth: 160
    property real islandHeight: 33
    property real landingY: 67
    property bool shown: false
    property real progress: shown ? 1 : 0

    signal closeRequested()
    signal expandToggled()
    // The badge is a quiet shortcut: lyrics move into the island, in place of the clock.
    signal islandRequested()

    readonly property int animationDuration: ThemeService.settings.notificationAnimationDuration ?? Theme.animationNormal
    readonly property real expansion: Math.max(0, (progress - 0.2) / 0.8)
    readonly property real startWidth: Math.min(width * 0.9, islandWidth * (ThemeService.settings.notificationStartWidthPercent ?? 50) / 100)
    readonly property real startHeight: Math.min(33, islandHeight)
    readonly property real originY: (islandHeight - startHeight) / 2
    // Animated card height, so expanding grows the card in place.
    property real cardHeight: IslandState.lyricsCardHeight
    // Ceiling from the screen (set by the window), so a tall panel above never pushes the card off-screen.
    property real maxHeight: 10000
    readonly property real fullHeight: Math.max(120, Math.min(cardHeight, maxHeight))
    readonly property alias surface: capsule

    readonly property color primaryText: Theme.textPrimary
    readonly property color secondaryText: Theme.textSecondary
    readonly property color mutedText: Theme.textMuted
    readonly property color accent: Theme.accent
    readonly property real trackProgress: MediaService.length > 0
        ? Math.max(0, Math.min(1, LyricsService.position / MediaService.length)) : 0

    readonly property string status: {
        if (!MediaService.hasPlayer) return "idle";
        if (LyricsService.hasLyrics) return "lyrics";
        if (LyricsService.loading) return "loading";
        return "none";
    }

    Behavior on cardHeight {
        NumberAnimation { duration: root.animationDuration; easing.type: Theme.animationVertical }
    }

    Behavior on progress {
        NumberAnimation { duration: root.animationDuration; easing.type: Theme.animationVertical }
    }

    ClippingRectangle {
        id: capsule

        objectName: "lyrics-capsule"
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.originY + (root.landingY - root.originY) * root.progress
        width: root.startWidth + (root.width - root.startWidth) * root.expansion
        height: root.startHeight + (root.fullHeight - root.startHeight) * root.expansion
        radius: ThemeService.settings.radius ?? Theme.capsuleRadius
        color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b,
            Theme.background.a * (ThemeService.settings.opacity ?? 1))

        border.width: 1
        border.color: Qt.alpha(root.accent, 0.22)

        // Flat tinted header band with a hairline divider.
        Rectangle {
            id: headerBand

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64
            color: Qt.alpha(root.accent, 0.08)

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.alpha(root.accent, 0.18)
            }
        }

        Item {
            id: content

            x: (parent.width - width) / 2
            width: root.width
            height: root.fullHeight
            opacity: Math.max(0, (root.progress - 0.3) / 0.7)

            // ---- Header ------------------------------------------------------------
            Item {
                id: header

                x: 20
                y: 12
                width: parent.width - 40
                height: 40

                Rectangle {
                    id: badge

                    width: 40
                    height: 40
                    radius: 12
                    color: Qt.alpha(root.accent, 0.16)
                    border.width: 1
                    border.color: Qt.alpha(root.accent, 0.35)

                    readonly property bool clickable: root.status === "lyrics"
                    readonly property bool hovering: clickable && badgeHover.hovered

                    SvgIcon {
                        id: badgeIcon

                        anchors.centerIn: parent
                        size: 20
                        source: "../assets/icons/lyrics.svg"
                        color: root.accent
                        opacity: badge.hovering ? 0.55 : 1

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blurMax: 24
                            blur: badge.hovering ? 1 : 0

                            Behavior on blur { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
                        }

                        Behavior on opacity { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
                    }

                    // Hover hint: the same lyrics, projected onto the island.
                    SvgIcon {
                        anchors.centerIn: parent
                        size: 20
                        source: "../assets/icons/cast.svg"
                        color: root.accent
                        opacity: badge.hovering ? 1 : 0
                        scale: badge.hovering ? 1 : 0.85

                        Behavior on opacity { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
                        Behavior on scale { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
                    }

                    HoverHandler { id: badgeHover }

                    // Only clickable once lyrics were actually found.
                    TapHandler {
                        enabled: badge.clickable
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.islandRequested()
                    }
                }

                Column {
                    anchors.left: badge.right
                    anchors.leftMargin: 12
                    anchors.right: expandButton.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    UiText {
                        width: parent.width
                        text: MediaService.title || "Lyrics"
                        color: root.primaryText
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    UiText {
                        width: parent.width
                        text: MediaService.artist
                        visible: text !== ""
                        color: root.mutedText
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    id: expandButton

                    objectName: "lyrics-expand"
                    width: 30
                    height: 30
                    radius: 15
                    anchors.right: closeButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    color: expandTap.pressed ? Theme.buttonPressed : expandHover.hovered ? Theme.surfaceVariant : Theme.surface

                    Behavior on color { ColorAnimation { duration: Theme.animationFast } }

                    Accessible.role: Accessible.Button
                    Accessible.name: IslandState.lyricsExpanded ? "Collapse lyrics" : "Expand lyrics"

                    SvgIcon {
                        anchors.centerIn: parent
                        size: 16
                        source: "../assets/icons/chevron-down.svg"
                        color: root.primaryText
                        rotation: IslandState.lyricsExpanded ? 180 : 0

                        Behavior on rotation {
                            NumberAnimation { duration: root.animationDuration; easing.type: Theme.animationVertical }
                        }
                    }

                    HoverHandler {
                        id: expandHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        id: expandTap
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.expandToggled()
                    }
                }

                Rectangle {
                    id: closeButton

                    objectName: "lyrics-close"
                    width: 30
                    height: 30
                    radius: 15
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    color: closeTap.pressed ? Theme.buttonPressed : closeHover.hovered ? Theme.surfaceVariant : Theme.surface

                    Behavior on color { ColorAnimation { duration: Theme.animationFast } }

                    Accessible.role: Accessible.Button
                    Accessible.name: "Close lyrics"

                    SvgIcon {
                        anchors.centerIn: parent
                        size: 16
                        source: "../assets/icons/close.svg"
                        color: root.primaryText
                    }

                    HoverHandler {
                        id: closeHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        id: closeTap
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.closeRequested()
                    }
                }
            }

            // ---- Lyrics --------------------------------------------------------------
            Item {
                id: body

                x: 12
                y: header.y + header.height + 18
                width: parent.width - 24
                height: root.fullHeight - y - 10

                ListView {
                    id: list

                    // Auto-follows the current line; scrolling by hand pauses that until it is idle.
                    property bool following: true
                    readonly property int target: LyricsService.currentIndex

                    function targetY(index) {
                        const item = list.itemAtIndex(index);
                        return item ? item.y + item.height / 2 - list.height / 2 : NaN;
                    }

                    function follow(animated) {
                        if (!list.following || list.target < 0)
                            return;
                        const y = list.targetY(list.target);
                        if (isNaN(y)) {
                            list.positionViewAtIndex(list.target, ListView.Center);
                            return;
                        }
                        followAnimation.stop();
                        if (animated && list.visible) {
                            followAnimation.to = y;
                            followAnimation.start();
                        } else {
                            list.contentY = y;
                        }
                    }

                    function resumeFollowing() {
                        list.following = true;
                        list.follow(true);
                    }

                    anchors.fill: parent
                    visible: opacity > 0
                    opacity: root.status === "lyrics" ? 1 : 0
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    spacing: 0
                    // Room above and below so the first and last lines can reach the centre.
                    topMargin: height / 2
                    bottomMargin: height / 2
                    // Every line stays laid out so the scroll target is exact.
                    cacheBuffer: 4000

                    model: LyricsService.lines

                    Behavior on opacity { NumberAnimation { duration: 260 } }

                    NumberAnimation {
                        id: followAnimation

                        target: list
                        property: "contentY"
                        duration: 450
                        easing.type: Easing.OutCubic
                    }

                    Timer {
                        id: idle

                        interval: 4000
                        onTriggered: list.resumeFollowing()
                    }

                    onTargetChanged: follow(true)
                    onHeightChanged: follow(false)
                    onCountChanged: Qt.callLater(() => { list.following = true; list.follow(false); })
                    onMovementStarted: {
                        followAnimation.stop();
                        list.following = false;
                        idle.restart();
                    }
                    onMovementEnded: idle.restart()

                    delegate: Item {
                        id: line

                        required property int index
                        required property string modelData

                        readonly property int distance: Math.abs(index - LyricsService.currentIndex)
                        readonly property bool current: distance === 0

                        width: list.width
                        height: label.implicitHeight + 14

                        UiText {
                            id: label

                            x: 20
                            y: 7
                            width: parent.width - 40
                            text: line.modelData.trim() === "" ? "♪" : line.modelData
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            font.pixelSize: 16
                            transformOrigin: Item.Center
                            scale: line.current ? 1.12 : 1
                            color: line.current ? root.accent : lineHover.hovered ? root.primaryText : root.secondaryText
                            opacity: line.current ? 1 : lineHover.hovered ? 0.95 : Math.max(0.3, 0.62 - line.distance * 0.1)

                            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        HoverHandler {
                            id: lineHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        // Click a line to jump the song to it.
                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: {
                                LyricsService.seekToLine(line.index);
                                list.resumeFollowing();
                            }
                        }
                    }
                }

                // Shown after scrolling away from the playing line.
                Rectangle {
                    id: currentPill

                    objectName: "lyrics-current"
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 6
                    width: pillLabel.implicitWidth + 24
                    height: 26
                    radius: 13
                    color: Qt.alpha(root.accent, pillTap.pressed ? 0.34 : 0.22)
                    border.width: 1
                    border.color: Qt.alpha(root.accent, 0.5)
                    opacity: !list.following && root.status === "lyrics" ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    UiText {
                        id: pillLabel

                        anchors.centerIn: parent
                        text: "Now playing"
                        color: root.accent
                        font.pixelSize: 11
                    }

                    HoverHandler { cursorShape: Qt.PointingHandCursor }

                    TapHandler {
                        id: pillTap
                        acceptedButtons: Qt.LeftButton
                        onTapped: list.resumeFollowing()
                    }
                }

                // ---- Placeholders ------------------------------------------------------
                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    opacity: root.status === "lyrics" ? 0 : 1
                    visible: opacity > 0

                    Behavior on opacity { NumberAnimation { duration: 260 } }

                    SvgIcon {
                        id: placeholderIcon

                        anchors.horizontalCenter: parent.horizontalCenter
                        size: 28
                        source: root.status === "idle" ? "../assets/icons/music-off.svg" : "../assets/icons/lyrics.svg"
                        color: root.mutedText

                        SequentialAnimation on opacity {
                            running: root.status === "loading" && root.shown
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                            onRunningChanged: if (!running) placeholderIcon.opacity = 1
                        }
                    }

                    UiText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.status === "loading" ? "Finding lyrics…"
                            : root.status === "idle" ? "Nothing playing"
                            : "No lyrics found"
                        color: root.secondaryText
                        font.pixelSize: 13
                    }
                }
            }
        }

        // Track progress along the bottom edge; click or drag to seek.
        SeekBar {
            id: seekBar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 16

            barHeight: 3
            hoverEffect: false
            radius: 0
            barCenterY: height - currentBarHeight / 2
            progress: root.trackProgress
            trackColor: Qt.alpha(root.accent, 0.14)
            fillColor: root.accent
            smoothDuration: 260
            opacity: content.opacity
            seekable: MediaService.length > 0 && (MediaService.player?.canSeek ?? false)

            onSeekRequested: fraction => LyricsService.seekTo(fraction * MediaService.length)
        }
    }
}
