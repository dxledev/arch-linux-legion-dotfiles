import QtQuick
import Caelestia.Config
import qs.components
import qs.services

Item {
    implicitWidth: Tokens.font.body.small.pointSize * 2
    implicitHeight: Tokens.font.body.small.pointSize * 2

    MaterialIcon {
        anchors.fill: parent
        animate: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Recorder.paused ? "pause_circle" : "screen_record"
        color: Recorder.paused ? Colours.palette.m3tertiary : Colours.palette.m3error
        fontStyle: Tokens.font.icon.medium
        fill: 1
    }
}
