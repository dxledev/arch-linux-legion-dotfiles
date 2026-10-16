import QtQuick
import "../services/RecordTargets.js" as RecordTargets
import "../styles"

// The recording popup's picture of what will be captured: every monitor drawn to scale, with viewfinder
// brackets around the target. The brackets glide between targets, and monitors and windows can be clicked.
Rectangle {
    id: root
    objectName: "record-viewfinder"

    property var screens: []
    property var windows: []
    property string mode: "screen"
    property string monitorName: ""
    property string windowAddress: ""
    property bool webcam: false
    // The webcam's top-left corner as a percent of the target.
    property real webcamX: 100
    property real webcamY: 100
    // Width over height of the camera's picture.
    property real cameraAspect: 4 / 3
    signal webcamMoved(real x, real y)
    signal webcamReleased()
    signal monitorPicked(string name)
    signal windowPicked(string address)

    readonly property real inset: 20
    readonly property var extent: RecordTargets.bounds(screens)
    readonly property real fit: extent.width > 0 && extent.height > 0
        ? Math.min((width - 2 * inset) / extent.width, (height - 2 * inset) / extent.height) : 1
    readonly property real originX: (width - extent.width * fit) / 2 - extent.x * fit
    readonly property real originY: (height - extent.height * fit) / 2 - extent.y * fit
    readonly property var chosenScreen: screens.find(screen => screen.name === monitorName) ?? screens[0] ?? null
    readonly property var chosenWindow: windows.find(window => window.address === windowAddress) ?? null

    // The target in the picture's own coordinates. Region has no rectangle until the user drags one, so
    // it shows a placeholder frame on the chosen monitor.
    readonly property var targetRect: {
        if (mode === "window") {
            return chosenWindow ? {x: chosenWindow.x, y: chosenWindow.y, width: chosenWindow.width, height: chosenWindow.height} : null;
        }
        if (!chosenScreen) return null;
        if (mode === "region") {
            const width = chosenScreen.width * 0.56, height = chosenScreen.height * 0.56;
            return {x: chosenScreen.x + (chosenScreen.width - width) / 2, y: chosenScreen.y + (chosenScreen.height - height) / 2, width: width, height: height};
        }
        return {x: chosenScreen.x, y: chosenScreen.y, width: chosenScreen.width, height: chosenScreen.height};
    }
    property real frameX: targetRect ? originX + targetRect.x * fit : width / 2
    property real frameY: targetRect ? originY + targetRect.y * fit : height / 2
    property real frameWidth: targetRect ? targetRect.width * fit : 0
    property real frameHeight: targetRect ? targetRect.height * fit : 0
    Behavior on frameX { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    Behavior on frameY { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    Behavior on frameWidth { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }
    Behavior on frameHeight { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic } }

    radius: 26
    color: Theme.surface
    clip: true

    Repeater {
        model: root.screens
        Rectangle {
            id: screenShape
            required property var modelData
            readonly property bool chosen: root.mode !== "window" && modelData.name === root.chosenScreen?.name
            x: root.originX + modelData.x * root.fit
            y: root.originY + modelData.y * root.fit
            width: modelData.width * root.fit
            height: modelData.height * root.fit
            radius: 6
            color: chosen && root.mode === "screen" ? Qt.alpha(Theme.accent, 0.22)
                : screenMouse.containsMouse && root.mode === "screen" ? Theme.card : Theme.surfaceVariant
            border.width: 1
            border.color: Qt.alpha(Theme.textPrimary, chosen ? 0.35 : 0.12)
            Behavior on color { ColorAnimation { duration: Theme.animationFast } }
            UiText {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 7
                text: screenShape.modelData.name
                color: Theme.textMuted
                font.pixelSize: 10
                visible: parent.width > 70
            }
            MouseArea {
                id: screenMouse
                objectName: "record-monitor-" + screenShape.modelData.name
                anchors.fill: parent
                enabled: root.mode === "screen"
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.monitorPicked(screenShape.modelData.name)
            }
        }
    }

    Repeater {
        model: root.mode === "window" ? root.windows : []
        Rectangle {
            id: windowShape
            required property var modelData
            required property int index
            readonly property bool chosen: modelData.address === root.windowAddress
            // Most recently used on top, matching what the screen shows.
            z: root.windows.length - index
            x: root.originX + modelData.x * root.fit
            y: root.originY + modelData.y * root.fit
            width: modelData.width * root.fit
            height: modelData.height * root.fit
            radius: 3
            color: chosen ? Qt.alpha(Theme.accent, 0.25) : windowMouse.containsMouse ? Qt.alpha(Theme.textPrimary, 0.16) : Qt.alpha(Theme.textPrimary, 0.07)
            border.width: 1
            border.color: Qt.alpha(Theme.textPrimary, chosen ? 0.5 : 0.22)
            Behavior on color { ColorAnimation { duration: Theme.animationFast } }
            MouseArea {
                id: windowMouse
                objectName: "record-window-" + windowShape.modelData.address
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.windowPicked(windowShape.modelData.address)
            }
        }
    }

    // Corner brackets around the target, like a camera's focus frame.
    Canvas {
        id: brackets
        anchors.fill: parent
        z: 100
        opacity: root.targetRect ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }
        readonly property real arm: Math.max(6, Math.min(16, Math.min(root.frameWidth, root.frameHeight) * 0.28))
        onArmChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections {
            target: root
            function onFrameXChanged() { brackets.requestPaint(); }
            function onFrameYChanged() { brackets.requestPaint(); }
            function onFrameWidthChanged() { brackets.requestPaint(); }
            function onFrameHeightChanged() { brackets.requestPaint(); }
        }
        Connections {
            target: Theme
            function onAccentChanged() { brackets.requestPaint(); }
        }
        onPaint: {
            const context = getContext("2d");
            context.reset();
            context.strokeStyle = Theme.accent;
            context.lineWidth = 2.5;
            context.lineCap = "round";
            context.lineJoin = "round";
            const left = root.frameX - 3, top = root.frameY - 3;
            const right = root.frameX + root.frameWidth + 3, bottom = root.frameY + root.frameHeight + 3;
            const arm = brackets.arm;
            context.beginPath();
            context.moveTo(left, top + arm); context.lineTo(left, top); context.lineTo(left + arm, top);
            context.moveTo(right - arm, top); context.lineTo(right, top); context.lineTo(right, top + arm);
            context.moveTo(right, bottom - arm); context.lineTo(right, bottom); context.lineTo(right - arm, bottom);
            context.moveTo(left + arm, bottom); context.lineTo(left, bottom); context.lineTo(left, bottom - arm);
            context.stroke();
        }
    }

    // The webcam, a quarter of the target's width and height, where it will be in the video. Drag it
    // anywhere inside the target.
    Rectangle {
        id: cameraBadge
        objectName: "record-webcam-badge"
        z: 101
        // The recorder fits the camera inside a box a quarter of the target's width and height, keeping its
        // proportions, so a 4:3 camera on a wide target is narrower than the box.
        readonly property real badgeWidth: root.frameWidth * root.cameraWidthShare
        readonly property real badgeHeight: root.frameHeight * root.cameraHeightShare
        x: root.frameX + root.frameWidth * Math.min(root.webcamX, root.maxX) / 100
        y: root.frameY + root.frameHeight * Math.min(root.webcamY, root.maxY) / 100
        width: badgeWidth
        height: badgeHeight
        radius: Math.min(6, height / 3)
        color: Theme.accent
        opacity: root.webcam && root.targetRect ? (dragArea.pressed ? 1 : 0.9) : 0
        scale: root.webcam ? 1 : 0.6
        visible: opacity > 0
        // x and y follow the frame's own animation, so the badge moves in step with the outline.
        Behavior on opacity { NumberAnimation { duration: Theme.animationFast } }
        Behavior on scale { NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutBack } }
        SvgIcon {
            anchors.centerIn: parent
            source: "../assets/icons/camera.svg"
            size: Math.max(8, Math.min(parent.width, parent.height) * 0.6)
            color: Theme.background
            visible: parent.width > 14 && parent.height > 12
        }
        MouseArea {
            id: dragArea
            objectName: "record-webcam-drag"
            property real grabX: 0
            property real grabY: 0
            anchors.fill: parent
            enabled: root.webcam && root.targetRect !== null
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            onPressed: mouse => { grabX = mouse.x; grabY = mouse.y; }
            onPositionChanged: mouse => {
                if (!pressed || root.frameWidth <= 0 || root.frameHeight <= 0) return;
                const point = mapToItem(root, mouse.x, mouse.y);
                root.webcamMoved(root.snap((point.x - grabX - root.frameX) / root.frameWidth * 100, root.maxX),
                    root.snap((point.y - grabY - root.frameY) / root.frameHeight * 100, root.maxY));
            }
            onReleased: root.webcamReleased()
        }
    }

    // Keeps the webcam inside the target.
    // The picture's share of the target's width and height. Taken from the target's real size, not the
    // animated outline, so a limit never changes while the outline glides to another display.
    readonly property real targetAspect: targetRect && targetRect.height > 0 ? targetRect.width / targetRect.height : 16 / 9
    readonly property real cameraWidthShare: targetAspect > cameraAspect ? 0.25 * cameraAspect / targetAspect : 0.25
    readonly property real cameraHeightShare: targetAspect > cameraAspect ? 0.25 : 0.25 * targetAspect / cameraAspect
    readonly property real maxX: 100 - cameraWidthShare * 100
    readonly property real maxY: 100 - cameraHeightShare * 100

    // The webcam goes where it is dropped. Only the edges stop it: 100 means against the right or bottom
    // edge whatever the picture's size, since the recorder holds the picture inside the video.
    function snap(percent, limit) {
        return percent <= 0 ? 0 : percent >= limit ? 100 : percent;
    }

    UiText {
        anchors.centerIn: parent
        visible: root.screens.length === 0 || (root.mode === "window" && !root.chosenWindow && root.windows.length === 0)
        text: root.screens.length === 0 ? "No monitors found" : "No windows to record"
        color: Theme.textMuted
        font.pixelSize: 13
    }
}
