import QtQuick
import QtQuick.Controls
import "../styles"
import "../components"

FocusScope {
    id: root
    required property LockAuth auth
    property string fontFamily: "Noto Sans"
    implicitWidth: 320
    implicitHeight: 94

    function focusInput(): void { input.forceActiveFocus(); }
    Component.onCompleted: focusInput()

    Connections {
        target: root.auth
        function onBusyChanged(): void { if (!root.auth.busy) root.focusInput(); }
        function onLockedChanged(): void { if (root.auth.locked) root.focusInput(); }
    }

    Rectangle {
        width: parent.width
        height: 54
        radius: height / 2
        color: Theme.surface
        border.width: 1
        border.color: root.auth.error ? Theme.danger : input.activeFocus ? Theme.accent : Theme.borderSubtle
        Behavior on border.color { ColorAnimation { duration: 150 } }

        SvgIcon {
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            source: "../assets/icons/lock.svg"
            size: 18
            color: Theme.textSecondary
        }

        TextField {
            id: input
            objectName: "lock-password"
            anchors.left: parent.left
            anchors.right: submitButton.left
            anchors.leftMargin: 48
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            padding: 0
            background: null
            font.family: root.fontFamily
            font.pixelSize: 14
            color: Theme.textPrimary
            placeholderText: root.auth.busy ? "Authenticating…" : "Password"
            placeholderTextColor: Theme.textMuted
            selectionColor: Theme.accent
            selectedTextColor: Theme.background
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

        Button {
            id: submitButton
            objectName: "lock-submit"
            anchors.right: parent.right
            anchors.rightMargin: 7
            anchors.verticalCenter: parent.verticalCenter
            width: 40
            height: 40
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
        anchors.topMargin: 65
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font.family: root.fontFamily
        font.pixelSize: 12
        color: root.auth.error ? Theme.danger : Theme.textMuted
        text: root.auth.error || (root.auth.busy ? "Verifying your password" : "Enter to unlock")
    }
}
