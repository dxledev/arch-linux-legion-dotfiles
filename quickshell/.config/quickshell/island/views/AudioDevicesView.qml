import QtQuick
import QtQuick.Layouts
import "../components"
import "../core"
import "../services"

FocusScope {
    id: root
    implicitWidth: 520
    implicitHeight: content.implicitHeight + 44
    focus: true

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        PanelHeader {
            Layout.fillWidth: true
            title: "Audio"
            scrollTargets: [outputs.scrollTarget, inputs.scrollTarget]
            onBack: IslandController.openControlCenter()
        }

        AudioDeviceSection {
            id: outputs
            objectName: "audio-outputs"
            Layout.fillWidth: true
            title: "Output"
            devices: AudioService.outputs
            currentDevice: AudioService.sink
            iconSource: "../assets/icons/volume-2.svg"
            onSelected: device => AudioService.selectOutput(device)
        }

        AudioDeviceSection {
            id: inputs
            objectName: "audio-inputs"
            Layout.fillWidth: true
            title: "Input"
            devices: AudioService.inputs
            currentDevice: AudioService.source
            iconSource: "../assets/icons/microphone.svg"
            onSelected: device => AudioService.selectInput(device)
        }
    }

    Keys.onEscapePressed: IslandController.openControlCenter()
}
