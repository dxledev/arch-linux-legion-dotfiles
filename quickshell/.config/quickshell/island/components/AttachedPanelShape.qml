import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    required property real panelHeight
    required property real panelRadius
    required property real drawerWidth
    property real joinRadius: panelRadius
    // Notch: the top edge sits flush with the screen and each top corner flares outward, in a
    // concave curve of `flare` px, into the screen edge. The width includes both flares.
    property bool notch: false
    property real flare: 0
    property real borderWidth: 0
    property color borderColor: "transparent"
    property color surfaceColor: "black"

    readonly property real inset: borderWidth / 2
    readonly property real flareRadius: notch ? flare + inset : 0
    // Body edges: the flares sit outside them in notch mode.
    readonly property real bodyLeft: (notch ? flare : 0) + inset
    readonly property real bodyRight: width - bodyLeft
    // The notch hides its top stroke above the screen edge instead of drawing a line along it.
    readonly property real bodyTop: notch ? -borderWidth : inset
    // The notch's bottom corners may be deeper than half the height: nothing round sits above them.
    readonly property real corner: Math.max(0, Math.min(panelRadius, notch ? panelHeight - flare : panelHeight / 2,
        width / 2 - (notch ? flare : 0)) - inset)
    readonly property real bottomEdge: height - inset
    readonly property real edge: panelHeight - inset
    readonly property real drawerLeft: (width - drawerWidth) / 2 + inset
    readonly property real drawerRight: width - drawerLeft
    readonly property real join: Math.max(0, Math.min(joinRadius, (height - panelHeight) / 2,
        drawerLeft - corner - bodyLeft))
    readonly property real foot: Math.max(0, Math.min(panelRadius, (height - panelHeight) / 2, drawerWidth / 2) - inset)

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeWidth: root.borderWidth
        strokeColor: root.borderWidth > 0 ? root.borderColor : "transparent"
        fillColor: root.surfaceColor
        startX: root.notch ? 0 : root.bodyLeft + root.corner
        startY: root.bodyTop

        PathLine { x: root.notch ? root.width : root.bodyRight - root.corner; y: root.bodyTop }
        PathArc {
            x: root.bodyRight; y: root.bodyTop + (root.notch ? root.flareRadius : root.corner)
            radiusX: root.notch ? root.flareRadius : root.corner
            radiusY: root.notch ? root.flareRadius : root.corner
            direction: root.notch ? PathArc.Counterclockwise : PathArc.Clockwise
        }
        PathLine { x: root.bodyRight; y: root.edge - root.corner }
        PathArc {
            x: root.bodyRight - root.corner; y: root.edge
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
        PathLine { x: root.bodyLeft + root.corner; y: root.edge }
        PathArc {
            x: root.bodyLeft; y: root.edge - root.corner
            radiusX: root.corner; radiusY: root.corner
        }
        PathLine { x: root.bodyLeft; y: root.bodyTop + (root.notch ? root.flareRadius : root.corner) }
        PathArc {
            x: root.notch ? 0 : root.bodyLeft + root.corner; y: root.bodyTop
            radiusX: root.notch ? root.flareRadius : root.corner
            radiusY: root.notch ? root.flareRadius : root.corner
            direction: root.notch ? PathArc.Counterclockwise : PathArc.Clockwise
        }
    }
}
