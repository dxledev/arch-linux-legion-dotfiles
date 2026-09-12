import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts

ColumnLayout {
    id: root
    spacing: 8
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Item {
            id: sv
            objectName: "chromackSaturationValue"
            Layout.fillWidth: true
            Layout.preferredHeight: Style.size("picker-height", 220)
            clip: true
            Rectangle {
                anchors.fill: parent
                color: Qt.hsva(ChromackState.data.hue / 359, 1, 1, 1)
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: "white"
                    }
                    GradientStop {
                        position: 1
                        color: "transparent"
                    }
                }
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 1
                        color: "black"
                    }
                }
            }
            Rectangle {
                x: ChromackState.data.saturation * sv.width - width / 2
                y: (1 - ChromackState.data.value) * sv.height - height / 2
                width: 16
                height: 16
                radius: 8
                color: "transparent"
                border.color: "#141414"
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    radius: 7
                    color: "transparent"
                    border.color: "white"
                    border.width: 2
                }
            }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                function select(mouse): void {
                    ChromackState.model.setHsv(ChromackState.data.hue, Math.max(0, Math.min(1, mouse.x / width)), 1 - Math.max(0, Math.min(1, mouse.y / height)), ChromackState.data.alpha);
                }
                onPressed: mouse => select(mouse)
                onPositionChanged: mouse => {
                    if (pressed)
                        select(mouse);
                }
            }
        }
        Item {
            id: hue
            objectName: "chromackHue"
            Layout.preferredWidth: Style.size("hue-width", 22)
            Layout.fillHeight: true
            Rectangle {
                anchors.fill: parent
                radius: 6
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#ff0000"
                    }
                    GradientStop {
                        position: 0.17
                        color: "#ffff00"
                    }
                    GradientStop {
                        position: 0.33
                        color: "#00ff00"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#00ffff"
                    }
                    GradientStop {
                        position: 0.67
                        color: "#0000ff"
                    }
                    GradientStop {
                        position: 0.83
                        color: "#ff00ff"
                    }
                    GradientStop {
                        position: 1
                        color: "#ff0000"
                    }
                }
            }
            Rectangle {
                x: -2
                width: parent.width + 4
                height: 12
                radius: 6
                y: ChromackState.data.hue / 359 * (parent.height - height)
                color: Style.value("hue-handle-bg", "#ffffff")
                border.color: Style.value("hue-handle-border-color", "#111111")
            }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                function select(mouse): void {
                    ChromackState.model.setHsv(Math.round(Math.max(0, Math.min(1, mouse.y / height)) * 359), ChromackState.data.saturation, ChromackState.data.value, ChromackState.data.alpha);
                }
                onPressed: mouse => select(mouse)
                onPositionChanged: mouse => {
                    if (pressed)
                        select(mouse);
                }
            }
        }
    }
    Label {
        text: "Material Colors"
        font.bold: true
        font.pixelSize: Style.size("section-title-size", 13)
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 16
        columnSpacing: 2
        rowSpacing: 2
        Repeater {
            model: ChromackState.data.materials
            Swatch {
                required property var modelData
                required property int index
                swatchColor: modelData.color
                Layout.fillWidth: true
                selected: ChromackState.data.selected === index
                tooltip: "Material " + String(index + 1).padStart(2, "0")
                onClicked: ChromackState.model.selectMaterial(index)
            }
        }
    }
    Label {
        text: "Recent Colors"
        font.bold: true
        font.pixelSize: Style.size("section-title-size", 13)
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 2
        Repeater {
            model: 16
            Swatch {
                required property int index
                readonly property var entry: ChromackState.data.recent[index]
                Layout.fillWidth: true
                enabled: !!entry
                swatchColor: entry?.color ?? "transparent"
                value: entry?.css ?? ""
                onClicked: ChromackState.model.setColor(value, false, false)
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Label {
            text: "Opacity"
        }
        QQC.Slider {
            id: alpha
            implicitHeight: Style.inputHeight
            objectName: "chromackOpacity"
            Layout.fillWidth: true
            from: 0
            to: 255
            stepSize: 1
            value: ChromackState.data.alpha
            onMoved: ChromackState.model.setAlpha(value)
            background: Rectangle {
                x: alpha.leftPadding
                y: (alpha.height - height) / 2
                width: alpha.availableWidth
                height: 10
                radius: 5
                color: Style.value("slider-track-bg", "#1f1d2e")
                border.color: Style.border
                Rectangle {
                    width: parent.width * alpha.visualPosition
                    height: parent.height
                    radius: 5
                    color: Style.value("slider-fill-bg", "#c4a7e7")
                }
            }
            handle: Rectangle {
                x: alpha.leftPadding + alpha.visualPosition * (alpha.availableWidth - width)
                y: (alpha.height - height) / 2
                width: 14
                height: 14
                radius: 7
                color: Style.value("slider-handle-bg", "white")
                border.color: Style.value("slider-handle-border-color", "#111111")
            }
        }
        Swatch {
            implicitWidth: Style.size("preview-width", 74)
            implicitHeight: Style.size("preview-height", 34)
            rounding: Style.size("preview-radius", 10)
            swatchColor: ChromackState.data.color
            value: ChromackState.data.css
            onClicked: ChromackState.model.copy(value)
        }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Label {
            text: "Hex"
        }
        Input {
            id: hex
            objectName: "chromackHex"
            Layout.fillWidth: true
            Layout.preferredWidth: 100
            sourceText: ChromackState.data.hex
            onSubmitted: value => invalid = !ChromackState.model.setColor(value)
            onAccepted: invalid = !ChromackState.model.generate(text)
        }
        Button {
            text: "󰆏"
            glyph: true
            glyphSize: 20
            tooltip: "Copy hex"
            onClicked: ChromackState.model.copy(ChromackState.data.hex)
        }
        Label {
            text: "RGBA"
        }
        Input {
            objectName: "chromackRgba"
            Layout.fillWidth: true
            Layout.preferredWidth: 145
            sourceText: ChromackState.data.rgba
            onSubmitted: value => invalid = !ChromackState.model.setColor(value)
            onAccepted: invalid = !ChromackState.model.generate(text)
        }
        Button {
            text: "󰆏"
            glyph: true
            glyphSize: 20
            tooltip: "Copy RGBA"
            onClicked: ChromackState.model.copy(ChromackState.data.rgba)
        }
    }
}
