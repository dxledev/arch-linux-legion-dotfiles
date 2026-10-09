pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import Shell.AppIcons

Item {
    id: root

    property url source
    property real implicitSize
    property bool colorize: false
    property color colour
    property bool light: false
    property bool capturePending: false
    property int generation: 0
    readonly property alias status: icon.status
    readonly property string captureKey: `${source}|${width}x${height}|${Screen.devicePixelRatio}`

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    onCaptureKeyChanged: invalidateCapture()
    onColorizeChanged: invalidateCapture()
    onVisibleChanged: requestCapture()

    function invalidateCapture(): void {
        generation++;
        raster.clear();
        requestCapture();
    }

    function requestCapture(): void {
        if (colorize && visible && status === Image.Ready && width > 0 && height > 0 && Window.window?.visible)
            captureTimer.restart();
    }

    function capture(): void {
        if (capturePending || raster.ready || !colorize || !visible || status !== Image.Ready || width <= 0 || height <= 0 || !Window.window?.visible)
            return;
        if (raster.restore(captureKey))
            return;
        capturePending = true;
        const revision = generation;
        const key = captureKey;
        const scale = Math.min(1, 128 / Math.max(width, height));
        const accepted = icon.grabToImage(result => {
            capturePending = false;
            if (generation !== revision || !colorize) {
                requestCapture();
                return;
            }
            raster.setImage(result.image, key);
        }, Qt.size(Math.max(1, Math.ceil(width * scale)), Math.max(1, Math.ceil(height * scale))));
        if (!accepted)
            capturePending = false;
    }

    IconImage {
        id: icon

        anchors.fill: parent
        source: root.source
        asynchronous: true
        onStatusChanged: root.invalidateCapture()
    }

    ShaderEffectSource {
        sourceItem: icon
        // Keep the original capturable without showing it while the tint is pending.
        hideSource: root.colorize
        visible: false
    }

    IconRaster {
        id: raster

        anchors.fill: parent
        tint: root.colour
        light: root.light
        visible: root.colorize && ready
    }

    Timer {
        id: captureTimer

        interval: 0
        onTriggered: root.capture()
    }

    Connections {
        target: root.Window.window
        function onVisibleChanged(): void {
            root.requestCapture();
        }
    }
}
