pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls

FocusScope {
    id: root

    property string title
    property string description
    property string confirmText
    property string errorText
    property bool busy: false

    signal confirmed
    signal cancelled

    implicitWidth: 420
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2
    width: parent ? Math.min(parent.width, implicitWidth) : implicitWidth
    height: implicitHeight
    visible: false
    z: 10

    Rectangle {
        anchors.fill: parent
        radius: Tokens.rounding.extraLarge
        color: Style.panel
        border.width: 1
        border.color: Style.outline
    }

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: root.title
            color: Style.text
            font: Tokens.font.title.small
        }

        StyledText {
            Layout.fillWidth: true
            text: root.description
            color: Style.muted
            wrapMode: Text.WordWrap
            font: Tokens.font.body.small
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.errorText.length > 0
            text: root.errorText
            color: Style.error
            wrapMode: Text.WordWrap
            font: Tokens.font.label.small
        }

        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            TextButton {
                id: cancelButton
                text: "Cancel"
                type: TextButton.Tonal
                enabled: !root.busy
                activeFocusOnTab: true
                onClicked: root.cancelled()
                Keys.onReturnPressed: root.cancelled()
                Keys.onSpacePressed: root.cancelled()
                Keys.onEscapePressed: event => {
                    root.cancelled();
                    event.accepted = true;
                }
                KeyNavigation.tab: confirmButton
            }

            TextButton {
                id: confirmButton
                text: root.busy ? "Clearing…" : root.confirmText
                type: TextButton.Filled
                activeColour: Style.error
                inactiveColour: Style.error
                activeOnColour: Style.onError
                inactiveOnColour: Style.onError
                enabled: !root.busy
                activeFocusOnTab: true
                onClicked: root.confirmed()
                Keys.onReturnPressed: root.confirmed()
                Keys.onSpacePressed: root.confirmed()
                Keys.onEscapePressed: event => {
                    root.cancelled();
                    event.accepted = true;
                }
                KeyNavigation.tab: cancelButton
            }
        }
    }

    Keys.onEscapePressed: event => {
        root.cancelled();
        event.accepted = true;
    }

    onVisibleChanged: {
        if (visible)
            Qt.callLater(() => cancelButton.forceActiveFocus());
    }
}
