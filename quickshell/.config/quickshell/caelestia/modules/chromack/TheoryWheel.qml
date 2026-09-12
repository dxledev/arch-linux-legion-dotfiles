import QtQuick

Canvas {
    id: root
    implicitHeight: 378
    property var segments: ChromackState.data.wheel
    property int hoveredIndex: -1
    property real innerRadiusRatio: 0.10
    onSegmentsChanged: requestPaint()
    onInnerRadiusRatioChanged: requestPaint()
    onHoveredIndexChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const radius = Math.min(width, height) / 2 - 4;
        const step = 2 * Math.PI / segments.length;
        for (let i = 0; i < segments.length; ++i) {
            ctx.beginPath();
            ctx.moveTo(width / 2, height / 2);
            ctx.arc(width / 2, height / 2, radius, -Math.PI / 2 + i * step, -Math.PI / 2 + (i + 1) * step);
            ctx.closePath();
            ctx.fillStyle = i === hoveredIndex ? Qt.lighter(segments[i].color, 1.18) : segments[i].color;
            ctx.fill();
            ctx.strokeStyle = Style.border;
            ctx.lineWidth = i === hoveredIndex ? 2 : 1;
            ctx.stroke();
        }
        ctx.beginPath();
        ctx.arc(width / 2, height / 2, radius * innerRadiusRatio, 0, 2 * Math.PI);
        ctx.fillStyle = Style.content;
        ctx.fill();
        ctx.lineWidth = 1;
        ctx.stroke();
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.hoveredIndex >= 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
        function segment(mouse): int {
            const x = mouse.x - width / 2, y = mouse.y - height / 2;
            const r = Math.sqrt(x * x + y * y), outer = Math.min(width, height) / 2 - 4;
            if (r < outer * root.innerRadiusRatio || r > outer)
                return -1;
            const angle = (Math.atan2(y, x) + Math.PI / 2 + 2 * Math.PI) % (2 * Math.PI);
            return Math.floor(angle / (2 * Math.PI) * root.segments.length);
        }
        onPositionChanged: mouse => root.hoveredIndex = segment(mouse)
        onExited: root.hoveredIndex = -1
        onClicked: mouse => {
            const i = segment(mouse);
            if (i >= 0)
                ChromackState.model.copy(root.segments[i].css);
        }
    }
}
