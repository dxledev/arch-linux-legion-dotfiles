import QtQuick
import QtQuick.Layouts
import "../services"
import "../styles"
import "../core"

ColumnLayout {
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            objectName: "audio-output-label"
            Layout.maximumWidth: Math.max(0, parent.width - 145 - audioButton.width - parent.spacing * 2)
            text: AudioService.outputLabel
            elide: Text.ElideRight
            color: Theme.textPrimary
            font.pixelSize: 12
        }

        IconButton {
            id: audioButton
            objectName: "open-audio-devices"
            implicitWidth: 24
            implicitHeight: 24
            padding: 3
            iconSource: "../assets/icons/more-horizontal.svg"
            description: "Choose audio output and input"
            onClicked: IslandController.openAudioDevices()
        }

        Item { Layout.fillWidth: true }

        Text {
            objectName: "audio-volume-label"
            text: AudioService.volume + "%"
            horizontalAlignment: Text.AlignRight
            color: Theme.textSecondary
            font.pixelSize: 12
        }
    }

    ControlSlider {
        Layout.fillWidth: true
        enabled: !!AudioService.sink?.ready
        iconSource: AudioService.volumeIcon
        value: Math.min(1, AudioService.volume / 100)
        Accessible.name: AudioService.outputLabel + " volume"
        onValueChangedByUser: value => AudioService.setVolume(value * 100)
    }
}
