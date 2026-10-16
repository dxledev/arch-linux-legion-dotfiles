import QtQuick
import "../core"
import "../services"
import "../styles"

// Screen recording controls for the workspace section: record opens the options popup, pause and
// stop act on the recording in progress (and rest dimmed while there is none), then the running time.
Row {
    id: root
    objectName: "record-controls"
    spacing: 8

    readonly property bool recording: RecorderService.running && !RecorderService.stopping

    WorkspaceChip {
        objectName: "record-start"
        anchors.verticalCenter: parent.verticalCenter
        iconSource: "../assets/icons/record.svg"
        iconColor: Theme.recording
        dimmed: !RecorderService.available
        enabled: RecorderService.available
        description: RecorderService.starting ? "Starting…" : "Record with the last settings (right-click for options)"
        // Left click repeats the last recording setup and folds the island away; right click opens the options.
        onClicked: {
            if (RecorderService.quickStart()) IslandController.reset();
            else IslandController.openRecordOptions();
        }
        onRightClicked: IslandController.openRecordOptions()
    }
    WorkspaceChip {
        objectName: "record-pause"
        anchors.verticalCenter: parent.verticalCenter
        iconSource: RecorderService.paused ? "../assets/icons/player-play.svg" : "../assets/icons/player-pause.svg"
        dimmed: !root.recording
        enabled: root.recording
        description: RecorderService.paused ? "Resume recording" : "Pause recording"
        onClicked: RecorderService.togglePause()
    }
    WorkspaceChip {
        objectName: "record-stop"
        anchors.verticalCenter: parent.verticalCenter
        iconSource: "../assets/icons/stop.svg"
        dimmed: !root.recording
        enabled: root.recording
        description: "Stop recording"
        onClicked: RecorderService.stop()
    }
    Row {
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: 6
        spacing: 8
        // The one moving part: a live recording breathes, a paused or saving one holds still.
        Rectangle {
            id: liveDot
            objectName: "record-live-dot"
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: Theme.recording
            visible: RecorderService.active
            opacity: root.recording && !RecorderService.paused ? 1 : 0.35
            SequentialAnimation on opacity {
                running: root.recording && !RecorderService.paused && liveDot.visible
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
            }
        }
        UiText {
            objectName: "record-duration"
            anchors.verticalCenter: parent.verticalCenter
            text: RecorderService.stopping ? "Saving…" : RecorderService.elapsedText
            color: RecorderService.running && !RecorderService.paused ? Theme.textPrimary : Theme.textSecondary
            font.pixelSize: 13
            font.weight: Font.Medium
            width: Math.max(implicitWidth, durationWidth.advanceWidth)
            TextMetrics {
                id: durationWidth
                font.family: Theme.uiFontFamily
                font.pixelSize: 13
                font.weight: Font.Medium
                text: "00:00"
            }
        }
    }
}
