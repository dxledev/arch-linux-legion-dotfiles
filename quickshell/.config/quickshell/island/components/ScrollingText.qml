import QtQuick

import "../styles"

Item {
    id: root

    property string text: ""
    property int maxWidth: 100
    property int fontSize: 13
    property color color: Theme.textPrimary
    // Marquee speed in pixels per second, so a slight overflow doesn't crawl.
    property real scrollSpeed: 36
    // Text that fits sits in the middle instead of against the left edge.
    property bool centered: false
    property bool bold: true

    width: maxWidth
    implicitHeight: label.implicitHeight

    clip: true

    UiText {
        id: label

        text: root.text

        color: root.color

        font.pixelSize: root.fontSize
        font.bold: root.bold

        anchors.verticalCenter: parent.verticalCenter

        x: root.restX
    }

    readonly property real restX: centered && label.width < maxWidth ? (maxWidth - label.width) / 2 : 0

    readonly property real overflow: label.width - root.maxWidth
    readonly property int scrollDuration: Math.max(1200, Math.round(overflow / scrollSpeed * 1000))

    SequentialAnimation {
        id: scrollAnimation

        loops: Animation.Infinite

        PauseAnimation {
            duration: 1800
        }

        NumberAnimation {
            target: label
            property: "x"

            to: -root.overflow

            duration: root.scrollDuration

            easing.type: Easing.InOutSine
        }

        PauseAnimation {
            duration: 1800
        }

        NumberAnimation {
            target: label
            property: "x"

            to: root.restX

            duration: root.scrollDuration

            easing.type: Easing.InOutSine
        }
    }

    // Any overflow scrolls; a few clipped pixels still cut off the title.
    function shouldScroll() {
        return label.width > root.maxWidth + 1
    }

    function refresh() {
        scrollAnimation.stop()

        label.x = root.restX

        if (shouldScroll())
            scrollAnimation.start()
    }

    onTextChanged: refresh()
    onMaxWidthChanged: refresh()

    // Restart scrolling only after the Text item has been laid out.
    // The width is not updated immediately when the text changes.
    Connections {
        target: label

        function onWidthChanged() {
            root.refresh()
        }
    }

    Component.onCompleted: refresh()
}
