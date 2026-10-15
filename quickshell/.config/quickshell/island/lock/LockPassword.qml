import QtQuick
import QtQuick.Controls
import "../services"
import "../styles"
import "../components"

FocusScope {
    id: root
    required property LockAuth auth
    property string fontFamily: "Noto Sans"
    // "default" draws filled circles, "random" cycles through different shapes (as Noctalia does).
    readonly property string maskStyle: ThemeService.settings.lockPasswordStyle ?? "default"
    readonly property int animationDuration: ThemeService.settings.lockAnimationDuration ?? 180
    readonly property real dotSize: 16
    readonly property real dotCell: 24
    property real shake: 0
    implicitWidth: 340
    implicitHeight: 100

    function focusInput(): void { input.forceActiveFocus(); }
    Component.onCompleted: focusInput()

    Connections {
        target: root.auth
        function onBusyChanged(): void { if (!root.auth.busy) root.focusInput(); }
        function onLockedChanged(): void { if (root.auth.locked) root.focusInput(); }
        function onErrorChanged(): void { if (root.auth.error && root.animationDuration > 0) shakeAnimation.restart(); }
    }

    SequentialAnimation {
        id: shakeAnimation
        NumberAnimation { target: root; property: "shake"; to: -9; duration: root.animationDuration * 0.25 }
        NumberAnimation { target: root; property: "shake"; to: 8; duration: root.animationDuration * 0.4 }
        NumberAnimation { target: root; property: "shake"; to: -4; duration: root.animationDuration * 0.35 }
        NumberAnimation { target: root; property: "shake"; to: 0; duration: root.animationDuration * 0.3; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: pill
        width: parent.width
        height: 58
        radius: height / 2
        color: Qt.alpha(Theme.surface, 0.84)
        border.width: root.auth.error || input.activeFocus ? 1.5 : 1
        border.color: root.auth.error ? Theme.danger
            : input.activeFocus ? Theme.accent : Qt.alpha(Theme.textPrimary, 0.08)
        transform: Translate { x: root.shake }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        SvgIcon {
            anchors.left: parent.left
            anchors.leftMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            source: "../assets/icons/lock.svg"
            size: 18
            color: root.auth.error ? Theme.danger : Theme.textSecondary
        }

        // The field itself stays a real masked TextField so input, focus and the shared buffer behave as
        // before; its glyphs are transparent and the dots below stand in for them.
        Item {
            id: field
            anchors.left: parent.left
            anchors.leftMargin: 56
            anchors.right: submitButton.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            clip: true

            TextField {
                id: input
                objectName: "lock-password"
                anchors.fill: parent
                leftPadding: 4
                rightPadding: 0
                topPadding: 0
                bottomPadding: 0
                verticalAlignment: TextInput.AlignVCenter
                background: null
                cursorDelegate: Item {}
                font.family: root.fontFamily
                font.pixelSize: 15
                color: "transparent"
                placeholderText: root.auth.busy ? "Checking…" : "Password"
                placeholderTextColor: Theme.textMuted
                selectionColor: "transparent"
                selectedTextColor: "transparent"
                echoMode: TextInput.Password
                passwordCharacter: "•"
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                maximumLength: 1024
                readOnly: false
                text: root.auth.buffer
                onTextEdited: root.auth.buffer = text
                onAccepted: root.auth.submit()
                Accessible.name: "Password"
                Keys.onEscapePressed: event => { root.auth.buffer = ""; event.accepted = true; }
            }

            Row {
                id: dots
                readonly property real overflow: Math.max(0, width - (field.width - 14))
                x: 4 - overflow
                height: parent.height
                Behavior on x { NumberAnimation { duration: root.animationDuration * 0.5; easing.type: Easing.OutCubic } }

                Repeater {
                    model: input.length
                    delegate: Item {
                        id: cell
                        required property int index
                        width: root.dotCell
                        height: dots.height
                        LockDot {
                            anchors.centerIn: parent
                            size: root.dotSize
                            kind: root.maskStyle === "random" ? cell.index : 0
                            color: root.auth.error ? Theme.danger : Theme.accent
                            popDuration: root.animationDuration * 0.9
                        }
                    }
                }
            }

            Rectangle {
                id: caret
                property bool on: true
                x: dots.x + input.length * root.dotCell + 2
                anchors.verticalCenter: parent.verticalCenter
                width: 2
                height: 20
                radius: 1
                color: Theme.accent
                visible: input.activeFocus && !root.auth.busy && on && input.length > 0
                Timer {
                    interval: 560
                    repeat: true
                    running: input.activeFocus && input.length > 0
                    onRunningChanged: caret.on = true
                    onTriggered: caret.on = !caret.on
                }
            }
        }

        Button {
            id: submitButton
            objectName: "lock-submit"
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 42
            height: 42
            enabled: true
            focusPolicy: Qt.NoFocus
            hoverEnabled: true
            Accessible.name: "Unlock"
            onClicked: { root.auth.submit(); root.focusInput(); }
            background: Rectangle {
                radius: height / 2
                color: submitButton.down ? Theme.accentPressed : submitButton.hovered ? Theme.accentHover : Theme.accent
            }
            contentItem: SvgIcon {
                source: "../assets/icons/chevron-right.svg"
                color: Theme.background
                size: 18
            }
        }
    }

    Text {
        objectName: "lock-message"
        anchors.top: parent.top
        anchors.topMargin: 72
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font.family: root.fontFamily
        font.pixelSize: 12
        color: root.auth.error ? Theme.danger : Theme.textMuted
        text: root.auth.error || (root.auth.busy ? "Verifying your password" : "Press Enter to unlock")
    }
}
