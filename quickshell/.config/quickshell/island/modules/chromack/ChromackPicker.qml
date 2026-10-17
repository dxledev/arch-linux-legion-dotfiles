pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../components"
import "../../styles"

// Saturation/value field, hue strip, opacity, colour inputs, material slots and
// recent colours. Material swatches select an editable slot; recents load a colour.
ColumnLayout {
    id: root
    spacing: 10
    readonly property var colorState: ChromackService.data
    property Item hexInput: null

    function setHsv(hue, saturation, value) {
        ChromackService.model.setHsv(hue, Math.max(0, Math.min(1, saturation)), Math.max(0, Math.min(1, value)), root.colorState.alpha);
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 168
        spacing: 10

        Item {
            id: field
            objectName: "chromack-saturation-value"
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Keyboard: the arrows nudge saturation and value; at an edge they move on to the next control.
            activeFocusOnTab: true
            Keys.onPressed: event => {
                const step = (event.modifiers & Qt.ShiftModifier) ? 0.1 : 0.02;
                const saturation = root.colorState.saturation;
                const value = root.colorState.value;
                let nextSaturation = saturation;
                let nextValue = value;
                if (event.key === Qt.Key_Left) nextSaturation = Math.max(0, saturation - step);
                else if (event.key === Qt.Key_Right) nextSaturation = Math.min(1, saturation + step);
                else if (event.key === Qt.Key_Up) nextValue = Math.min(1, value + step);
                else if (event.key === Qt.Key_Down) nextValue = Math.max(0, value - step);
                else return;
                if (nextSaturation === saturation && nextValue === value) return;
                root.setHsv(root.colorState.hue, nextSaturation, nextValue);
                event.accepted = true;
            }
            FocusRing { radius: 10 }

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: Qt.hsva(root.colorState.hue / 359, 1, 1, 1)
            }
            Rectangle {
                anchors.fill: parent
                radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: "white" }
                    GradientStop { position: 1; color: "transparent" }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: 10
                gradient: Gradient {
                    GradientStop { position: 0; color: "transparent" }
                    GradientStop { position: 1; color: "black" }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: 10
                color: "transparent"
                border.width: 1
                border.color: Theme.border
            }
            Rectangle {
                x: root.colorState.saturation * field.width - width / 2
                y: (1 - root.colorState.value) * field.height - height / 2
                width: 16
                height: 16
                radius: 8
                color: "transparent"
                border.width: 2
                border.color: "white"
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    radius: 9
                    color: "transparent"
                    border.color: "#80000000"
                }
            }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.CrossCursor
                function select(mouse) {
                    root.setHsv(root.colorState.hue, mouse.x / width, 1 - mouse.y / height);
                }
                onPressed: mouse => select(mouse)
                onPositionChanged: mouse => { if (pressed) select(mouse); }
            }
        }

        Item {
            id: hueStrip
            objectName: "chromack-hue"
            Layout.preferredWidth: 22
            Layout.fillHeight: true

            // Keyboard: Up and Down turn the hue; at either end they move on to the next control.
            activeFocusOnTab: true
            Keys.onPressed: event => {
                const step = (event.modifiers & Qt.ShiftModifier) ? 20 : 4;
                const hue = root.colorState.hue;
                let nextHue = hue;
                if (event.key === Qt.Key_Up) nextHue = Math.max(0, hue - step);
                else if (event.key === Qt.Key_Down) nextHue = Math.min(359, hue + step);
                else return;
                if (nextHue === hue) return;
                root.setHsv(nextHue, root.colorState.saturation, root.colorState.value);
                event.accepted = true;
            }
            FocusRing { radius: 8 }

            Rectangle {
                anchors.fill: parent
                radius: 8
                border.width: 1
                border.color: Theme.border
                gradient: Gradient {
                    GradientStop { position: 0; color: "#ff0000" }
                    GradientStop { position: 0.17; color: "#ffff00" }
                    GradientStop { position: 0.33; color: "#00ff00" }
                    GradientStop { position: 0.5; color: "#00ffff" }
                    GradientStop { position: 0.67; color: "#0000ff" }
                    GradientStop { position: 0.83; color: "#ff00ff" }
                    GradientStop { position: 1; color: "#ff0000" }
                }
            }
            Rectangle {
                x: -3
                y: root.colorState.hue / 359 * (parent.height - height)
                width: parent.width + 6
                height: 10
                radius: 5
                color: Theme.textPrimary
                border.width: 1
                border.color: Theme.background
            }
            MouseArea {
                anchors.fill: parent
                preventStealing: true
                cursorShape: Qt.PointingHandCursor
                function select(mouse) {
                    root.setHsv(Math.round(Math.max(0, Math.min(1, mouse.y / height)) * 359), root.colorState.saturation, root.colorState.value);
                }
                onPressed: mouse => select(mouse)
                onPositionChanged: mouse => { if (pressed) select(mouse); }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        UiText {
            text: "Opacity"
            color: Theme.textSecondary
            font.pixelSize: 12
            Layout.preferredWidth: 46
        }

        Slider {
            id: alpha
            objectName: "chromack-opacity"
            Layout.fillWidth: true
            from: 0
            to: 255
            stepSize: 1
            value: root.colorState.alpha
            onMoved: ChromackService.model.setAlpha(value)
            background: Rectangle {
                x: alpha.leftPadding
                y: (alpha.height - height) / 2
                width: alpha.availableWidth
                height: 6
                radius: 3
                color: Theme.sliderBackground
                Rectangle {
                    width: parent.width * alpha.visualPosition
                    height: parent.height
                    radius: 3
                    color: Theme.sliderFill
                }
            }
            handle: Rectangle {
                x: alpha.leftPadding + alpha.visualPosition * (alpha.availableWidth - width)
                y: (alpha.height - height) / 2
                width: 16
                height: 16
                radius: 8
                color: Theme.textPrimary
                border.width: 1
                border.color: Theme.background
            }
        }

        ChromackSwatch {
            objectName: "chromack-preview"
            implicitWidth: 64
            implicitHeight: 30
            rounding: 10
            swatchColor: root.colorState.color
            value: root.colorState.css
            description: "Copy " + root.colorState.css
            onClicked: ChromackService.copy(value)
        }
    }

    Repeater {
        model: [
            { label: "Hex", key: "hex", name: "chromack-hex", placeholder: "#5f6b7b" },
            { label: "RGBA", key: "rgba", name: "chromack-rgba", placeholder: "rgba(95, 107, 123, 1)" }
        ]

        RowLayout {
            id: formatRow
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: 10

            UiText {
                text: formatRow.modelData.label
                color: Theme.textSecondary
                font.pixelSize: 12
                Layout.preferredWidth: 46
            }

            ChromackInput {
                id: formatInput
                objectName: formatRow.modelData.name
                Layout.fillWidth: true
                sourceText: root.colorState[formatRow.modelData.key] ?? ""
                placeholderText: formatRow.modelData.placeholder
                onSubmitted: (value, accepted) => invalid = !(accepted
                    ? ChromackService.model.generate(value) : ChromackService.model.setColor(value))
                Component.onCompleted: if (formatRow.index === 0) root.hexInput = formatInput
            }

            IconButton {
                objectName: formatRow.modelData.name + "-copy"
                implicitWidth: 34
                implicitHeight: 34
                padding: 8
                iconSource: "../assets/icons/copy.svg"
                description: "Copy " + formatRow.modelData.label
                focusPolicy: Qt.NoFocus
                onClicked: ChromackService.copy(root.colorState[formatRow.modelData.key])
            }
        }
    }

    UiText {
        Layout.topMargin: 2
        text: "Material colors"
        color: Theme.textPrimary
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 16
        columnSpacing: 3
        rowSpacing: 3

        Repeater {
            model: root.colorState.materials

            ChromackSwatch {
                required property var modelData
                required property int index
                objectName: "chromack-material-" + index
                Layout.fillWidth: true
                implicitHeight: 20
                swatchColor: modelData.color
                selected: root.colorState.selected === index
                description: "Material " + String(index + 1).padStart(2, "0") + " · " + modelData.css
                onClicked: ChromackService.model.selectMaterial(index)
            }
        }
    }

    UiText {
        Layout.topMargin: 2
        text: "Recent colors"
        color: Theme.textPrimary
        font.pixelSize: 13
        font.weight: Font.DemiBold
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 3

        Repeater {
            model: 16

            ChromackSwatch {
                required property int index
                readonly property var entry: root.colorState.recent[index]
                objectName: "chromack-recent-" + index
                Layout.fillWidth: true
                implicitHeight: 20
                enabled: !!entry
                swatchColor: entry?.color ?? "transparent"
                value: entry?.css ?? ""
                onClicked: ChromackService.model.setColor(value, false, false)
            }
        }
    }
}
