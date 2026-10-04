import QtQuick
import QtQuick.Shapes
import "../styles"

Shape {
    id: root
    objectName: "notification-countdown-ring"

    property real progress: 1
    property real thickness: 2
    property color ringColor: Theme.accent
    property color trackColor: Theme.surfaceVariant
    readonly property real ringRadius: Math.max(0, (Math.min(width, height) - thickness) / 2)

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        strokeColor: root.trackColor
        strokeWidth: root.thickness
        fillColor: "transparent"
        PathAngleArc {
            centerX: root.width / 2
            centerY: root.height / 2
            radiusX: root.ringRadius
            radiusY: root.ringRadius
            startAngle: -90
            sweepAngle: 360
        }
    }

    ShapePath {
        strokeColor: root.progress > 0 ? root.ringColor : "transparent"
        strokeWidth: root.thickness
        capStyle: ShapePath.RoundCap
        fillColor: "transparent"
        PathAngleArc {
            centerX: root.width / 2
            centerY: root.height / 2
            radiusX: root.ringRadius
            radiusY: root.ringRadius
            startAngle: -90
            sweepAngle: 360 * Math.max(0, Math.min(1, root.progress))
        }
    }
}
