pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import "../components"
import "../core"
import "../island"
import "../services"
import "../services/RecordTargets.js" as RecordTargets
import "../styles"

// What to record, and with what: opened by the record button under the workspace section. The picture at
// the top shows the target to scale; Start folds the island away and then starts the recorder.
FocusScope {
    id: root
    objectName: "record-options"

    property var screens: []
    property var windows: []
    readonly property bool hasCamera: RecorderService.cameras.length > 0
    readonly property string folder: RecorderService.shortDirectory || "Videos/Recordings"
    readonly property string format: String(ThemeService.settings.recordFormat || "mp4").toUpperCase()
    readonly property string startLabel: RecorderService.starting ? "Starting…"
        : RecorderService.mode === "region" ? "Select area and record" : "Start recording"

    implicitWidth: 560
    implicitHeight: body.y + body.implicitHeight + 24

    function reload() {
        const monitors = Hyprland.monitors.values.map(monitor => monitor.lastIpcObject);
        const clients = Hyprland.toplevels.values.map(toplevel => toplevel.lastIpcObject);
        // Assigning an equal list would still rebuild every delegate, resetting scrolling, hover and focus.
        const nextScreens = RecordTargets.screens(monitors), nextWindows = RecordTargets.windows(clients, monitors);
        if (JSON.stringify(nextScreens) !== JSON.stringify(screens)) screens = nextScreens;
        if (JSON.stringify(nextWindows) !== JSON.stringify(windows)) windows = nextWindows;
        // Choices from an earlier recording that no longer exist fall back to something recordable.
        if (screens.length > 0 && !screens.some(screen => screen.name === RecorderService.monitorName)) {
            const panelScreen = screens.find(screen => screen.name === IslandState.panelMonitorName);
            RecorderService.monitorName = (panelScreen ?? screens.find(screen => screen.focused) ?? screens[0])?.name ?? "";
        }
        // Window mode starts on the window in use, so Start is ready without another click.
        if (screens.length > 0 && !windows.some(window => window.address === RecorderService.windowAddress))
            RecorderService.windowAddress = windows[0]?.address ?? "";
    }

    function refresh() {
        Hyprland.refreshMonitors();
        Hyprland.refreshToplevels();
        reload();
    }

    function start() {
        if (!RecorderService.canStart) return;
        RecorderService.start();
        IslandController.reset();
    }

    Component.onCompleted: {
        refresh();
        RecorderService.refreshCameras();
        forceActiveFocus();
    }
    Keys.onEscapePressed: IslandController.reset()
    Keys.onReturnPressed: start()
    Keys.onEnterPressed: start()

    Connections {
        target: Hyprland.toplevels
        function onValuesChanged() { root.reload(); }
    }
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    PanelHeader {
        id: header
        x: 24
        y: 20
        width: parent.width - 48
        title: "Record screen"
        onBack: IslandController.closeRecordOptions()
    }

    Column {
        id: body
        x: 24
        y: header.y + header.height + 14
        width: parent.width - 48
        spacing: 12

        RecordViewfinder {
            width: parent.width
            height: 150
            screens: root.screens
            windows: root.windows
            mode: RecorderService.mode
            monitorName: RecorderService.monitorName
            windowAddress: RecorderService.windowAddress
            webcam: RecorderService.webcam && root.hasCamera
            cameraAspect: RecorderService.cameraAspect
            webcamX: RecorderService.webcamX
            webcamY: RecorderService.webcamY
            onWebcamMoved: (x, y) => { RecorderService.webcamX = x; RecorderService.webcamY = y; }
            onWebcamReleased: RecorderService.saveChoices()
            onMonitorPicked: name => RecorderService.monitorName = name
            onWindowPicked: address => RecorderService.windowAddress = address
        }

        Row {
            id: modes
            width: parent.width
            spacing: 8
            readonly property real cell: (width - 2 * spacing) / 3
            Repeater {
                model: [
                    {key: "region", label: "Region", icon: "../assets/icons/region.svg"},
                    {key: "screen", label: "Screen", icon: "../assets/icons/display.svg"},
                    {key: "window", label: "Window", icon: "../assets/icons/window.svg"}
                ]
                RecordChoice {
                    required property var modelData
                    objectName: "record-mode-" + modelData.key
                    width: modes.cell
                    text: modelData.label
                    iconSource: modelData.icon
                    selected: RecorderService.mode === modelData.key
                    onClicked: RecorderService.mode = modelData.key
                }
            }
        }

        // Each mode takes only the room it needs: a hint, the monitor buttons, or a short window list.
        Item {
            id: context
            width: parent.width
            height: RecorderService.mode === "window" ? 108
                : RecorderService.mode === "screen" ? monitorFlow.height : regionHint.implicitHeight
            Behavior on height { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }

            Column {
                id: regionHint
                visible: RecorderService.mode === "region"
                width: parent.width
                spacing: 6
                UiText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Drag to choose the area"
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
                UiText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    text: "After you press the button, drag across any part of any monitor. Esc cancels."
                    color: Theme.textMuted
                    font.pixelSize: 12
                }
            }

            Flow {
                id: monitorFlow
                visible: RecorderService.mode === "screen"
                width: parent.width
                spacing: 8
                Repeater {
                    model: root.screens
                    RecordChoice {
                        required property var modelData
                        objectName: "record-screen-" + modelData.name
                        text: modelData.name
                        detail: modelData.pixelWidth + " × " + modelData.pixelHeight
                        iconSource: "../assets/icons/display.svg"
                        selected: RecorderService.monitorName === modelData.name
                        onClicked: RecorderService.monitorName = modelData.name
                    }
                }
            }

            ListView {
                id: windowList
                objectName: "record-window-list"
                visible: RecorderService.mode === "window"
                anchors.fill: parent
                clip: true
                spacing: 6
                model: root.windows
                boundsBehavior: Flickable.StopAtBounds
                SmoothScroll { scrollTarget: windowList }
                ScrollBar.vertical: ScrollBar {
                    width: 4
                    contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.textMuted; opacity: 0.5 }
                }
                UiText {
                    anchors.centerIn: parent
                    visible: windowList.count === 0
                    text: "No windows on screen to record"
                    color: Theme.textMuted
                    font.pixelSize: 13
                }
                delegate: Button {
                    id: windowRow
                    required property var modelData
                    readonly property bool selected: modelData.address === RecorderService.windowAddress
                    objectName: "record-window-row-" + modelData.address
                    width: ListView.view.width - 10
                    height: 46
                    leftPadding: 14
                    rightPadding: 14
                    hoverEnabled: true
                    focusPolicy: Qt.TabFocus
                    Accessible.name: modelData.title
                    onClicked: RecorderService.windowAddress = modelData.address
                    HoverHandler {
                        enabled: windowRow.hovered
                        cursorShape: Qt.PointingHandCursor
                    }
                    contentItem: Row {
                        spacing: 12
                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 22
                            height: 22
                            Image {
                                id: appIcon
                                anchors.fill: parent
                                source: windowRow.modelData.appClass ? Quickshell.iconPath(windowRow.modelData.appClass.toLowerCase(), true) : ""
                                sourceSize: Qt.size(44, 44)
                                fillMode: Image.PreserveAspectFit
                                visible: status === Image.Ready
                            }
                            SvgIcon {
                                visible: !appIcon.visible
                                source: "../assets/icons/window.svg"
                                size: 18
                                color: windowRow.selected ? Theme.background : Theme.textSecondary
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: windowRow.availableWidth - 34
                            UiText {
                                width: parent.width
                                text: windowRow.modelData.title
                                elide: Text.ElideRight
                                color: windowRow.selected ? Theme.background : Theme.textPrimary
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                            UiText {
                                width: parent.width
                                text: "Workspace " + windowRow.modelData.workspace + " on " + windowRow.modelData.monitor
                                elide: Text.ElideRight
                                color: windowRow.selected ? Qt.alpha(Theme.background, 0.7) : Theme.textMuted
                                font.pixelSize: 11
                            }
                        }
                    }
                    background: Rectangle {
                        radius: 16
                        color: windowRow.selected ? Theme.accent : windowRow.down ? Theme.buttonPressed : windowRow.hovered ? Theme.surfaceVariant : Theme.surface
                        border.width: windowRow.activeFocus ? 2 : 0
                        border.color: windowRow.selected ? Theme.textPrimary : Theme.accent
                        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                    }
                }
            }
        }

        Row {
            id: extras
            width: parent.width
            spacing: 8
            readonly property real cell: (width - spacing) / 2
            RecordChoice {
                objectName: "record-webcam"
                width: extras.cell
                text: "Webcam"
                detail: root.hasCamera ? (RecorderService.webcam ? "Drag to position" : "Off") : "No webcam found"
                iconSource: "../assets/icons/camera.svg"
                enabled: root.hasCamera
                selected: RecorderService.webcam && root.hasCamera
                onClicked: RecorderService.webcam = !RecorderService.webcam
            }
            RecordChoice {
                objectName: "record-audio"
                width: extras.cell
                text: "Sound"
                detail: RecorderService.audio ? "System audio" : "Off"
                iconSource: "../assets/icons/volume-2.svg"
                selected: RecorderService.audio
                onClicked: RecorderService.audio = !RecorderService.audio
            }
        }

        Button {
            id: startButton
            objectName: "record-start-button"
            width: parent.width
            height: 48
            enabled: RecorderService.canStart
            hoverEnabled: true
            focusPolicy: Qt.TabFocus
            Accessible.name: root.startLabel
            onClicked: root.start()
            HoverHandler {
                enabled: startButton.enabled && startButton.hovered
                cursorShape: Qt.PointingHandCursor
            }
            contentItem: Item {
                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    SvgIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        source: "../assets/icons/record.svg"
                        size: 18
                        color: Theme.background
                    }
                    UiText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.startLabel
                        color: Theme.background
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                }
            }
            background: Rectangle {
                radius: 24
                color: startButton.down ? Qt.darker(Theme.recording, 1.15) : startButton.hovered ? Qt.lighter(Theme.recording, 1.1) : Theme.recording
                opacity: startButton.enabled ? 1 : 0.4
                border.width: startButton.activeFocus ? 2 : 0
                border.color: Theme.textPrimary
                Behavior on color { ColorAnimation { duration: Theme.animationFast } }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            UiText {
                anchors.verticalCenter: parent.verticalCenter
                // A long folder shortens in the middle instead of running out of the panel.
                width: Math.min(implicitWidth, body.width - settingsLink.width - parent.spacing)
                elide: Text.ElideMiddle
                text: "Saved as " + root.format + " in " + root.folder + "."
                color: Theme.textMuted
                font.pixelSize: 11
            }
            UiText {
                id: settingsLink
                objectName: "record-settings-link"
                anchors.verticalCenter: parent.verticalCenter
                text: "Change"
                color: linkMouse.containsMouse ? Theme.textPrimary : Theme.accent
                font.pixelSize: 11
                font.underline: linkMouse.containsMouse
                Accessible.role: Accessible.Button
                Accessible.name: "Open screen recording settings"
                MouseArea {
                    id: linkMouse
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: IslandController.openSettingsSection("screenRecording")
                }
            }
        }
    }
}
