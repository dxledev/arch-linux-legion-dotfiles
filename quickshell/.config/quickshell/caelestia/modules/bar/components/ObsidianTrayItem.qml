import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

MouseArea {
    id: root

    readonly property string popoutName: "traymenu:obsidian"

    acceptedButtons: Qt.LeftButton
    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2

    onClicked: Quickshell.execDetached([
        "/home/dxle/bin/hypr-focus-special-workspace",
        "scratchpad"
    ])

    MaterialIcon {
        anchors.fill: parent
        animate: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        text: "edit_note"
        color: Colours.palette.m3onSurface
        fontStyle: Tokens.font.icon.medium
        fill: 1
    }
}
