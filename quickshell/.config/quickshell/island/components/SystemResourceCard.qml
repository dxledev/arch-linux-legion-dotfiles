import QtQuick
import "../styles"

Rectangle {
    id: root
    required property string title
    required property string detail
    required property real usage
    required property var history
    property real displayedUsage: 0
    implicitHeight: 218
    radius: 18
    color: Theme.surface
    Component.onCompleted: displayedUsage = usage
    onUsageChanged: displayedUsage = usage
    Behavior on displayedUsage { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

    UiText {
        x: 16; y: 16
        text: root.title
        font.pixelSize: 14; font.weight: Font.DemiBold
        color: Theme.textPrimary
    }
    CountdownRing {
        id: ring
        width: 84; height: 84
        anchors.horizontalCenter: parent.horizontalCenter
        y: 48
        thickness: 5
        progress: root.displayedUsage
        UiText {
            anchors.centerIn: parent
            text: Math.round(root.displayedUsage * 100) + "%"
            font.pixelSize: 21; font.weight: Font.DemiBold
            color: Theme.textPrimary
        }
    }
    UiText {
        x: 12; y: 144; width: parent.width - 24
        text: root.detail
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        font.pixelSize: 11
        color: Theme.textSecondary
    }
    Canvas {
        id: graph
        x: 16; y: 175; width: parent.width - 32; height: 27
        property var samples: root.history
        onSamplesChanged: requestPaint()
        Connections { target: Theme; function onAccentChanged() { graph.requestPaint(); } }
        onPaint: {
            const context = getContext("2d");
            context.reset();
            if (samples.length < 2) return;
            context.strokeStyle = Theme.accent;
            context.lineWidth = 2;
            context.lineJoin = "round";
            context.beginPath();
            for (let i = 0; i < samples.length; i++) {
                const x = i * width / 29;
                const y = 2 + (1 - samples[i]) * (height - 4);
                if (i === 0) context.moveTo(x, y); else context.lineTo(x, y);
            }
            context.stroke();
        }
    }
}
