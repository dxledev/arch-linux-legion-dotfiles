import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property real panelHeight
    required property real panelRadius
    required property real drawerWidth
    property real joinRadius: panelRadius
    property real borderWidth: 0
    property color borderColor: "transparent"
    property color surfaceColor: "black"

    readonly property real inset: borderWidth / 2
    readonly property real corner: Math.max(0, Math.min(panelRadius, panelHeight / 2, width / 2) - inset)
    readonly property real bottomEdge: height - inset
    readonly property real edge: panelHeight - inset
    readonly property real drawerLeft: (width - drawerWidth) / 2 + inset
    readonly property real drawerRight: width - drawerLeft
    readonly property real join: Math.max(0, Math.min(joinRadius, (height - panelHeight) / 2,
        drawerLeft - corner - inset))
    readonly property real foot: Math.max(0, Math.min(panelRadius, (height - panelHeight) / 2, drawerWidth / 2) - inset)

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: root.borderWidth
        strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
        fillColor: root.surfaceColor
        startX: root.inset + root.corner
        startY: root.inset

        PathLine { x: root.width - root.inset - root.corner; y: root.inset }
        PathArc {
            x: root.width - root.inset; y: root.inset + root.corner
            radiusX: root.corner; radiusY: root.corner
        }
        PathLine { x: root.width - root.inset; y: root.edge - root.corner }
        PathArc {
            x: root.width - root.inset - root.corner; y: root.edge
            radiusX: root.corner; radiusY: root.corner
        }
        PathLine { x: root.drawerRight + root.join; y: root.edge }
        PathArc {
            x: root.drawerRight; y: root.edge + root.join
            radiusX: root.join; radiusY: root.join
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.drawerRight; y: root.bottomEdge - root.foot }
        PathArc {
            x: root.drawerRight - root.foot; y: root.bottomEdge
            radiusX: root.foot; radiusY: root.foot
        }
        PathLine { x: root.drawerLeft + root.foot; y: root.bottomEdge }
        PathArc {
            x: root.drawerLeft; y: root.bottomEdge - root.foot
            radiusX: root.foot; radiusY: root.foot
        }
        PathLine { x: root.drawerLeft; y: root.edge + root.join }
        PathArc {
            x: root.drawerLeft - root.join; y: root.edge
            radiusX: root.join; radiusY: root.join
            direction: PathArc.Counterclockwise
        }
        PathLine { x: root.inset + root.corner; y: root.edge }
        PathArc {
            x: root.inset; y: root.edge - root.corner
            radiusX: root.corner; radiusY: root.corner
        }
        PathLine { x: root.inset; y: root.inset + root.corner }
        PathArc {
            x: root.inset + root.corner; y: root.inset
            radiusX: root.corner; radiusY: root.corner
        }
    }
}
