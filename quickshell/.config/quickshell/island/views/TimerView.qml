pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../components"
import "../core"
import "../island"
import "../services"
import "../services/TimerLogic.js" as TimerLogic
import "../styles"

// Set a countdown and see the ones running. Type digits like a microwave (1 5 0 0 is 15:00), turn the dial, or
// add minutes with the buttons; Enter starts it. Several timers can run at once, each with its own label.
FocusScope {
    id: root
    objectName: "timer-panel"

    // What has been typed, read from the right as hhmmss; the dial and the buttons rewrite it.
    property string digits: ""
    readonly property int seconds: TimerLogic.digitsToSeconds(digits)
    readonly property bool full: TimerService.timers.length >= TimerLogic.maximumTimers
    readonly property bool canStart: seconds > 0 && !full
    readonly property string startLabel: full ? "Too many timers running"
        : seconds > 0 ? "Start " + TimerLogic.describe(seconds) + " timer" : "Start timer"
    readonly property int rowHeight: 52
    readonly property int visibleRows: 2

    implicitWidth: 760
    implicitHeight: body.y + body.implicitHeight + 24

    function setSeconds(value) { digits = TimerLogic.secondsToDigits(value); }

    function start() {
        if (!canStart) return;
        TimerService.start(seconds, labelField.text, TimerService.keepAlert);
        digits = "";
        labelField.text = "";
        root.forceActiveFocus();
    }

    function endsAtText(timer) {
        return new Date(timer.endsAt).toLocaleTimeString(Qt.locale(), Locale.ShortFormat);
    }

    // Digits, Backspace, Delete and Enter work from anywhere in the panel that does not take them itself (the
    // label field keeps its own typing). True when the key was used.
    function pressKey(key, text) {
        if (/^[0-9]$/.test(text)) digits = TimerLogic.appendDigit(digits, text);
        else if (key === Qt.Key_Backspace) digits = TimerLogic.removeDigit(digits);
        else if (key === Qt.Key_Delete) digits = "";
        else if (key === Qt.Key_Return || key === Qt.Key_Enter) start();
        else return false;
        return true;
    }

    Component.onCompleted: forceActiveFocus()
    // A sound previewed here does not outlive the panel.
    Component.onDestruction: TimerService.stopPreview()
    Keys.onPressed: event => { event.accepted = pressKey(event.key, event.text); }
    Keys.onEscapePressed: IslandController.reset()

    // A labelled on/off switch, the width of the panel.
    component PanelSwitch: Switch {
        id: panelSwitch
        width: parent.width
        height: 40
        padding: 0
        contentItem: UiText {
            text: panelSwitch.text
            color: Theme.textPrimary
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
            rightPadding: 64
        }
        indicator: Rectangle {
            x: panelSwitch.width - width
            y: (panelSwitch.height - height) / 2
            width: 50
            height: 30
            radius: 15
            color: panelSwitch.checked ? Theme.accent : Theme.surfaceVariant
            border.width: panelSwitch.activeFocus ? 2 : 0
            border.color: Theme.textPrimary
            Behavior on color { ColorAnimation { duration: Theme.animationFast } }
            Rectangle {
                x: panelSwitch.checked ? parent.width - width - 3 : 3
                y: 3
                width: 24
                height: 24
                radius: 12
                color: panelSwitch.checked ? Theme.background : Theme.textPrimary
                Behavior on x { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
            }
        }
    }

    // A block that opens under its switch: it takes no room, and cannot be reached, while it is shut.
    component Reveal: Item {
        id: reveal
        property bool shown: false
        default property alias content: holder.data
        width: parent.width
        height: shown ? holder.height : 0
        opacity: shown ? 1 : 0
        visible: opacity > 0
        clip: true
        Behavior on height { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
        Item {
            id: holder
            width: parent.width
            height: childrenRect.height
        }
    }

    PanelHeader {
        id: header
        x: 24
        y: 20
        width: parent.width - 48
        title: "Timer"
        onBack: IslandController.openNavigation()
    }

    Column {
        id: body
        x: 24
        y: header.y + header.height + 8
        width: parent.width - 48
        spacing: 14

        // Two columns: the time on the left (dial, minutes, label), what happens when it ends on the right.
        Row {
            id: columns
            width: parent.width
            spacing: 28
            readonly property real columnWidth: (width - spacing) / 2

            Column {
                id: timeColumn
                objectName: "timer-time-column"
                width: columns.columnWidth
                spacing: 14

                Item {
                    width: parent.width
                    height: dial.height
                    TimerDial {
                        id: dial
                        anchors.horizontalCenter: parent.horizontalCenter
                        seconds: root.seconds
                        onMinutesPicked: minutes => root.setSeconds(minutes * 60)
                    }
                }

                Row {
                    id: presets
                    width: parent.width
                    spacing: 8
                    readonly property real cell: (width - 3 * spacing) / 4
                    Repeater {
                        model: [
                            {key: "1", label: "+1 min", minutes: 1},
                            {key: "5", label: "+5 min", minutes: 5},
                            {key: "10", label: "+10 min", minutes: 10},
                            {key: "clear", label: "Clear", minutes: 0}
                        ]
                        Button {
                            id: preset
                            required property var modelData
                            readonly property bool clear: modelData.minutes === 0
                            objectName: "timer-preset-" + modelData.key
                            width: presets.cell
                            height: 36
                            enabled: clear ? root.seconds > 0 : true
                            hoverEnabled: true
                            focusPolicy: Qt.TabFocus
                            Accessible.name: clear ? "Clear time" : "Add " + modelData.minutes + (modelData.minutes === 1 ? " minute" : " minutes")
                            onClicked: clear ? root.digits = "" : root.setSeconds(TimerLogic.addMinutes(root.seconds, modelData.minutes))
                            HoverHandler {
                                enabled: preset.enabled && preset.hovered
                                cursorShape: Qt.PointingHandCursor
                            }
                            contentItem: UiText {
                                text: preset.modelData.label
                                color: preset.clear ? Theme.textSecondary : Theme.textPrimary
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                radius: height / 2
                                opacity: preset.enabled ? 1 : 0.4
                                color: preset.down ? Theme.buttonPressed : preset.hovered ? Theme.surfaceVariant : Theme.surface
                                border.width: preset.activeFocus ? 2 : 0
                                border.color: Theme.accent
                                Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                            }
                        }
                    }
                }

                SearchField {
                    id: labelField
                    objectName: "timer-label-field"
                    width: parent.width
                    placeholderText: "Label (optional)"
                    maximumLength: TimerLogic.maximumLabelLength
                    Accessible.name: "Timer label"
                    onAccepted: root.start()
                }
            }

            Column {
                id: optionsColumn
                objectName: "timer-options-column"
                width: columns.columnWidth
                spacing: 14

                PanelSwitch {
                    id: keepAlert
                    objectName: "timer-keep-alert"
                    text: "Indefinite alert"
                    checked: TimerService.keepAlert
                    onToggled: TimerService.setKeepAlert(checked)
                }

                PanelSwitch {
                    id: soundSwitch
                    objectName: "timer-sound-switch"
                    text: "Alert sound"
                    checked: TimerService.soundEnabled
                    onToggled: TimerService.setSoundEnabled(checked)
                }

                // The sound to play, only while sound is on. Nothing plays until a play button is pressed; choosing another
                // sound cuts off the one still being previewed.
                Reveal {
                    objectName: "timer-sounds"
                    shown: TimerService.soundEnabled

                    SettingChoice {
                        id: soundChoice
                        label: ""
                        within: root
                        enabled: TimerService.soundEnabled
                        choices: TimerService.sounds.map(sound => sound.key)
                        selected: TimerService.soundName
                        choiceLabel: key => TimerService.sounds.find(sound => sound.key === key)?.label ?? key
                        previewable: true
                        previewing: TimerService.previewKey
                        onChosen: key => {
                            TimerService.stopPreview();
                            TimerService.setSoundName(key);
                        }
                        onPreviewToggled: key => {
                            if (TimerService.previewKey === key) TimerService.stopSound();
                            else TimerService.preview(key);
                        }
                    }
                }

                PanelSwitch {
                    id: snoozeSwitch
                    objectName: "timer-snooze-switch"
                    text: "Allow snooze"
                    checked: TimerService.snoozeEnabled
                    onToggled: TimerService.setSnoozeEnabled(checked)
                }

                // How long a snooze lasts, only while snoozing is allowed. The alert then has a Snooze button.
                Reveal {
                    objectName: "timer-snooze"
                    shown: TimerService.snoozeEnabled

                    SettingChoice {
                        id: snoozeChoice
                        label: ""
                        within: root
                        enabled: TimerService.snoozeEnabled
                        // The chosen length is always listed, even one set from outside the panel.
                        choices: [...new Set([...TimerLogic.snoozeChoices, TimerService.snoozeSeconds])]
                            .sort((a, b) => a - b).map(String)
                        selected: String(TimerService.snoozeSeconds)
                        choiceLabel: seconds => "Snooze for " + TimerLogic.describe(Number(seconds))
                        onChosen: seconds => TimerService.setSnoozeSeconds(Number(seconds))
                    }
                }
            }
        }

        Button {
            id: startButton
            objectName: "timer-start-button"
            width: parent.width
            height: 48
            enabled: root.canStart
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
                        source: "../assets/icons/player-play.svg"
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
                color: startButton.down ? Theme.accentPressed : startButton.hovered ? Theme.accentHover : Theme.accent
                opacity: startButton.enabled ? 1 : 0.4
                border.width: startButton.activeFocus ? 2 : 0
                border.color: Theme.textPrimary
                Behavior on color { ColorAnimation { duration: Theme.animationFast } }
            }
        }

        Column {
            id: running
            objectName: "timer-running"
            width: parent.width
            spacing: 8
            visible: TimerService.active

            UiText {
                text: TimerService.timers.length === 1 ? "1 timer running" : TimerService.timers.length + " timers running"
                color: Theme.textSecondary
                font.pixelSize: 13
                font.weight: Font.Medium
            }

            ListView {
                id: list
                objectName: "timer-list"
                width: parent.width
                height: Math.min(count, root.visibleRows) * (root.rowHeight + spacing) - spacing
                clip: true
                spacing: 6
                model: TimerService.timers
                boundsBehavior: Flickable.StopAtBounds
                SmoothScroll { scrollTarget: list }
                ScrollBar.vertical: ScrollBar {
                    width: 4
                    contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.textMuted; opacity: 0.5 }
                }
                delegate: Rectangle {
                    id: timerRow
                    required property var modelData
                    readonly property bool urgent: TimerLogic.isUrgent(modelData, TimerService.now)
                    objectName: "timer-row-" + modelData.id
                    width: ListView.view.width - 10
                    height: root.rowHeight
                    radius: 16
                    color: Theme.surface

                    CountdownRing {
                        id: rowRing
                        objectName: "timer-row-ring"
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        thickness: 3
                        progress: TimerLogic.progress(timerRow.modelData, TimerService.now)
                        ringColor: timerRow.modelData.paused ? Theme.textSecondary : timerRow.urgent ? Theme.warning : Theme.accent
                    }
                    Column {
                        anchors.left: rowRing.right
                        anchors.leftMargin: 12
                        anchors.right: remaining.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        UiText {
                            objectName: "timer-row-label"
                            width: parent.width
                            text: timerRow.modelData.label || "Timer"
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        UiText {
                            width: parent.width
                            text: timerRow.modelData.paused ? "Paused"
                                : "Ends at " + root.endsAtText(timerRow.modelData)
                                + (timerRow.modelData.indefinite ? ", alert stays until closed" : "")
                            color: Theme.textMuted
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                    UiText {
                        id: remaining
                        objectName: "timer-row-remaining"
                        anchors.right: pauseButton.left
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        text: TimerLogic.formatRemaining(TimerLogic.remainingMs(timerRow.modelData, TimerService.now))
                        color: timerRow.modelData.paused ? Theme.textSecondary : timerRow.urgent ? Theme.warning : Theme.textPrimary
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    IconButton {
                        id: pauseButton
                        objectName: "timer-row-pause"
                        anchors.right: cancelButton.left
                        anchors.rightMargin: 2
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 32
                        implicitHeight: 32
                        iconSource: timerRow.modelData.paused ? "../assets/icons/player-play.svg" : "../assets/icons/player-pause.svg"
                        description: timerRow.modelData.paused ? "Resume timer" : "Pause timer"
                        onClicked: TimerService.togglePause(timerRow.modelData.id)
                    }
                    IconButton {
                        id: cancelButton
                        objectName: "timer-row-cancel"
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 32
                        implicitHeight: 32
                        iconSource: "../assets/icons/close.svg"
                        description: "Cancel timer"
                        onClicked: TimerService.cancel(timerRow.modelData.id)
                    }
                }
            }
        }
    }
}
