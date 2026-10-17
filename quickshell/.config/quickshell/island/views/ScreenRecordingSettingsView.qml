import QtQuick
import "../components"
import "../services"

SettingsPanel {
    id: root
    title: "Screen recording"
    maximumHeight: 635
    scrollObjectName: "screen-recording-scroll"
    readonly property var cameraChoices: ["auto"].concat(RecorderService.cameras)
    Component.onCompleted: RecorderService.refreshCameras()

    SettingSection {
        title: "Saving"
        iconSource: "../assets/icons/folder.svg"
        SettingChoice {
            label: "Format"
            choices: ["mp4", "mkv", "mov", "webm"]
            choiceLabel: value => value.toUpperCase()
            selected: ThemeService.settings.recordFormat || "mp4"
            onChosen: value => ThemeService.setSetting("recordFormat", value)
        }
        SettingText {
            label: "File name (date codes: %Y %m %d %H %M %S)"
            setting: "recordFilename"
            placeholder: "recording_%Y%m%d_%H-%M-%S"
        }
        SettingText {
            label: "Save recordings to"
            setting: "recordDirectory"
            placeholder: RecorderService.directory || "Videos/Recordings"
        }
        Row {
            spacing: 8
            TextActionButton {
                objectName: "record-choose-directory"
                text: RecorderService.choosingDirectory ? "Choosing\u2026" : "Choose folder\u2026"
                enabled: !RecorderService.choosingDirectory && !ThemeService.busy
                onClicked: RecorderService.chooseDirectory()
            }
            TextActionButton {
                text: "Use the default folder"
                visible: (ThemeService.settings.recordDirectory ?? "") !== ""
                onClicked: ThemeService.setSetting("recordDirectory", "")
            }
        }
    }
    SettingSection {
        title: "Video"
        iconSource: "../assets/icons/screen-record.svg"
        SettingChoice {
            label: "Quality"
            choices: ["medium", "high", "very_high", "ultra"]
            choiceLabel: value => ({medium: "Medium", high: "High", very_high: "Very high", ultra: "Ultra"})[value] ?? value
            selected: ThemeService.settings.recordQuality || "very_high"
            onChosen: value => ThemeService.setSetting("recordQuality", value)
        }
        SettingChoice {
            label: "Frame rate"
            choices: ["auto", "30", "60"]
            choiceLabel: value => value === "auto" ? "Match the monitor" : value + " fps"
            selected: String(ThemeService.settings.recordFramerate || "60")
            onChosen: value => ThemeService.setSetting("recordFramerate", value)
        }
        SettingToggle { text: "Show the mouse cursor"; setting: "recordCursor" }
    }
    SettingSection {
        title: "Webcam"
        iconSource: "../assets/icons/camera.svg"
        SettingChoice {
            label: "Camera"
            choices: root.cameraChoices
            choiceLabel: value => value === "auto" ? "First available" : RecorderService.cameraLabel(value)
            selected: ThemeService.settings.recordCameraDevice || "auto"
            onChosen: value => ThemeService.setSetting("recordCameraDevice", value)
        }
    }
}
