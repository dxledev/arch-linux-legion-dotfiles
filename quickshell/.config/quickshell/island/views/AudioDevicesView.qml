import QtQuick
import "../components"
import "../core"
import "../services"
import "../styles"

FocusScope {
    id: root
    property bool optionsVisible: false
    implicitWidth: 520
    // Report the target height so the Island animates once while the options row reveals in step.
    implicitHeight: 44 + header.implicitHeight + optionsReveal.targetHeight + outputs.implicitHeight
        + inputs.implicitHeight + content.spacing * 2
    focus: true

    Column {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        PanelHeader {
            id: header
            width: parent.width
            title: "Audio"
            titleActionIcon: root.optionsVisible ? "../assets/icons/chevron-up.svg" : "../assets/icons/chevron-down.svg"
            titleActionDescription: root.optionsVisible ? "Hide audio options" : "Show audio options"
            titleActionActive: root.optionsVisible
            scrollTargets: [outputs.scrollTarget, inputs.scrollTarget]
            onTitleActionClicked: root.optionsVisible = !root.optionsVisible
            onBack: IslandController.openControlCenter()
        }

        // Plain positioning keeps the outputs in step with the reveal; a layout would trail it by a polish pass.
        Item {
            width: parent.width
            height: optionsReveal.height + outputs.height

            Item {
                id: optionsReveal
                readonly property real targetHeight: root.optionsVisible ? options.implicitHeight + content.spacing : 0
                // Overhang the clip so fractional panel positions cannot shave the section's side borders.
                x: -2
                width: parent.width + 4
                height: targetHeight
                clip: true
                visible: root.optionsVisible || height > 0
                Behavior on height {
                    NumberAnimation {
                        duration: ThemeService.settings.islandAnimationDuration ?? 300
                        easing.type: Theme.animationVertical
                    }
                }

                SettingSection {
                    id: options
                    objectName: "audio-options"
                    x: 2
                    width: parent.width - 4
                    opacity: optionsReveal.targetHeight > 0 ? Math.min(1, optionsReveal.height / optionsReveal.targetHeight) : 0
                    title: "Options"
                    iconSource: "../assets/icons/settings.svg"

                    SettingToggle {
                        objectName: "audio-allow-over-amplification"
                        text: "Allow volume above 100%"
                        setting: "audioAllowOverAmplification"
                    }

                    SettingSlider {
                        objectName: "audio-over-amplification-limit"
                        label: "Extra volume"
                        setting: "audioOverAmplificationLimit"
                        prefix: "+"
                        suffix: "%"
                        minimum: 1
                        maximum: 50
                        enabled: AudioService.overAmplification
                    }
                }
            }

            AudioDeviceSection {
                id: outputs
                objectName: "audio-outputs"
                y: optionsReveal.height
                width: parent.width
                title: "Output"
                devices: AudioService.outputs
                currentDevice: AudioService.sink
                iconSource: "../assets/icons/volume-2.svg"
                onSelected: device => AudioService.selectOutput(device)
            }
        }

        AudioDeviceSection {
            id: inputs
            objectName: "audio-inputs"
            width: parent.width
            title: "Input"
            devices: AudioService.inputs
            currentDevice: AudioService.source
            iconSource: "../assets/icons/microphone.svg"
            onSelected: device => AudioService.selectInput(device)
        }
    }

    Keys.onEscapePressed: {
        if (optionsVisible)
            optionsVisible = false
        else
            IslandController.reset()
    }
}
