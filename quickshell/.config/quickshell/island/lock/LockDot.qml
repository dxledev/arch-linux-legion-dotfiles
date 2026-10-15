import QtQuick
import QtQuick.Shapes
import "LockDots.js" as LockDots

// One masked password character. It pops in when typed; `kind` picks the glyph (see LockDots.js).
Item {
    id: root

    property int kind: 0
    property real size: 14
    property color color: "white"
    property int popDuration: 160
    property bool shown: false

    width: size
    height: size
    scale: shown ? 1 : 0.2
    opacity: shown ? 1 : 0
    rotation: shown ? 0 : -30

    Component.onCompleted: shown = true

    Behavior on scale { NumberAnimation { duration: root.popDuration; easing.type: Easing.OutBack } }
    Behavior on opacity { NumberAnimation { duration: root.popDuration } }
    Behavior on rotation { NumberAnimation { duration: root.popDuration; easing.type: Easing.OutCubic } }

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: root.color
            strokeColor: root.color
            strokeWidth: 2.5
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: LockDots.points(root.kind) }
        }
    }
}
