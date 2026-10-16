import QtQuick
import "../services"
import "../styles"

// Red dot that blinks while a screen recording runs; clicking it stops the recording. Paused or saving, it
// holds still and dim. Position it beside the clock (the dot sits 6 px inside the item, so put the item 1 px past the
// clock's edge to keep the click area off the clock); it takes no part in any layout. The item is larger than the
// dot so it is easy to hit.
Item {
    id: root
    objectName: "recording-indicator"
    readonly property bool live: RecorderService.running && !RecorderService.paused && !RecorderService.stopping
    readonly property alias dot: dot

    width: 18
    height: 22
    visible: RecorderService.active
    Accessible.role: Accessible.Button
    Accessible.name: RecorderService.stopping ? "Saving recording" : RecorderService.paused ? "Recording paused, stop recording" : "Recording, stop recording"
    Accessible.onPressAction: RecorderService.stop()

    Rectangle {
        id: dot
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 8
        radius: 4
        color: Theme.recording
        opacity: root.live ? 1 : 0.4

        SequentialAnimation on opacity {
            running: root.live && root.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.15; duration: 550; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 550; easing.type: Easing.InOutSine }
        }
    }

    MouseArea {
        objectName: "recording-indicator-stop"
        anchors.fill: parent
        enabled: RecorderService.running && !RecorderService.stopping
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: RecorderService.stop()
    }
}
