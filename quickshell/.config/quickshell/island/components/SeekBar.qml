import QtQuick

// Thin progress bar that seeks: click anywhere on it, or drag. The bar thickens on hover and a
// knob appears while hovered or dragged. Emits seekRequested(fraction) when the press is released.
Item {
    id: root

    property real progress: 0
    property color trackColor: "#33FFFFFF"
    property color fillColor: "#FFFFFF"
    property real barHeight: 4
    property real hoverBarHeight: 6
    property real radius: 2
    // Vertical centre of the bar inside this item.
    property real barCenterY: height / 2
    // Smooths the 1 Hz position ticks; off while dragging.
    property int smoothDuration: 0
    property bool seekable: true
    // Off: no thickening or knob on hover or drag (seeking still works).
    property bool hoverEffect: true

    readonly property bool pressed: area.pressed
    readonly property bool hovered: area.containsMouse
    readonly property real currentBarHeight: hoverEffect && (pressed || hovered) ? hoverBarHeight : barHeight
    property real dragFraction: 0
    readonly property real shownFraction: pressed ? dragFraction : Math.max(0, Math.min(1, progress))
    // Only the fraction is smoothed, never the pixel width: when the panel morphs open the bar's
    // width changes every frame and a width animation would trail behind, spilling past the card.
    property real displayFraction: shownFraction

    Behavior on displayFraction {
        enabled: root.smoothDuration > 0 && !root.pressed
        NumberAnimation { duration: root.smoothDuration; easing.type: Easing.Linear }
    }

    signal seekRequested(real fraction)

    implicitHeight: 24

    Rectangle {
        id: track

        width: parent.width
        height: root.currentBarHeight
        y: root.barCenterY - height / 2
        radius: root.radius
        color: root.trackColor

        Behavior on height { NumberAnimation { duration: 120 } }

        Rectangle {
            id: fill

            height: parent.height
            radius: parent.radius
            width: parent.width * root.displayFraction
            color: root.fillColor
        }

        Rectangle {
            width: 12
            height: 12
            radius: 6
            x: fill.width - width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: root.fillColor
            opacity: root.hoverEffect && root.seekable && (root.pressed || root.hovered) ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 120 } }
        }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        enabled: root.seekable
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function fractionAt(x) {
            return Math.max(0, Math.min(1, x / Math.max(1, root.width)));
        }

        onPressed: mouse => root.dragFraction = fractionAt(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                root.dragFraction = fractionAt(mouse.x);
        }
        onReleased: mouse => root.seekRequested(fractionAt(mouse.x))
    }
}
