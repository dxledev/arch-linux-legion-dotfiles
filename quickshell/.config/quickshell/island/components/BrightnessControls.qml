pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import "../services"
import "../styles"

Flickable {
    id: root

    property var monitors: BrightnessService.monitors
    readonly property bool scrollAnimationRunning: wheelScroll.animating
    implicitHeight: Math.min(rows.implicitHeight, 180)
    contentWidth: width
    contentHeight: rows.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    SmoothScroll { id: wheelScroll; scrollTarget: root }
    ScrollBar.vertical: ScrollBar {}

    Column {
        id: rows
        width: root.width
        spacing: 12

        Repeater {
            model: root.monitors

            Column {
                id: row
                required property var modelData
                objectName: "brightness-" + modelData.connector
                width: rows.width
                spacing: 4
                opacity: modelData.supported ? 1 : 0.5

                Row {
                    width: parent.width
                    Text {
                        width: parent.width - 145
                        text: row.modelData.label
                        elide: Text.ElideRight
                        color: Theme.textPrimary
                        font.pixelSize: 12
                    }
                    Text {
                        width: 145
                        text: !row.modelData.supported ? "Unsupported" : row.modelData.error || (row.modelData.initialized ? row.modelData.brightness + "%" : "Loading…")
                        horizontalAlignment: Text.AlignRight
                        color: Theme.textSecondary
                        font.pixelSize: 12
                    }
                }

                ControlSlider {
                    width: parent.width
                    enabled: row.modelData.supported && row.modelData.initialized
                    iconSource: row.modelData.icon
                    value: row.modelData.brightness / 100
                    Accessible.name: row.modelData.label + " brightness"
                    onValueChangedByUser: value => row.modelData.setBrightness(value * 100)
                }
            }
        }
    }

    Timer {
        interval: Math.max(1000, Number(Quickshell.env("ISLAND_BRIGHTNESS_POLL_MS")) || 5000)
        repeat: true
        running: root.visible
        onTriggered: BrightnessService.refresh()
    }

    Component.onCompleted: BrightnessService.refresh()
}
