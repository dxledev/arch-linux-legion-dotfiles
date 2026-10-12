pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property var sink: null
    readonly property var source: null
    readonly property var outputs: []
    readonly property var inputs: []
    readonly property string outputLabel: "Isolated audio"
    readonly property int volume: 0
    readonly property bool muted: false
    readonly property bool overAmplification: false
    readonly property int maxVolume: 100
    readonly property url volumeIcon: Qt.resolvedUrl("../assets/icons/volume-off.svg")

    function setVolume(value) {}
    function toggleMute() {}
    function selectOutput(node) {}
    function selectInput(node) {}
}
