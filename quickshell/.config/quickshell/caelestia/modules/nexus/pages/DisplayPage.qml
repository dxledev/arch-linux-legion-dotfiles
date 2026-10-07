pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.services
import qs.modules.display
import qs.modules.nexus.common

PageBase {
    id: root

    title: Tr.tr("Display")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        RowButton {
            first: true
            last: true
            icon: "monitor"
            text: Tr.tr("Open Layout Editor")
            trailingIcon: "open_in_new"
            onClicked: Display.open()
        }

        SectionHeader { text: Tr.tr("Monitors") }

        Repeater {
            model: Brightness.monitors

            ColumnLayout {
                id: monitorGroup

                required property var modelData

                Layout.fillWidth: true
                Layout.bottomMargin: Tokens.spacing.medium
                spacing: Tokens.spacing.extraSmall / 2

                TextFieldRow {
                    objectName: "monitor-nickname-" + monitorGroup.modelData.modelData.name
                    first: true
                    label: monitorGroup.modelData.displayName
                    subtext: Tr.tr("Monitor nickname")
                    placeholderText: monitorGroup.modelData.modelData.name
                    maximumLength: 64
                    value: DisplaySettings.nickname(monitorGroup.modelData.modelData.name)
                    enabled: DisplaySettings.ready
                    onEditingFinished: value => DisplaySettings.setNickname(monitorGroup.modelData.modelData.name, value)
                }

                SliderRow {
                    objectName: "monitor-brightness-" + monitorGroup.modelData.modelData.name
                    last: true
                    icon: "brightness_6"
                    label: Tr.tr("Brightness")
                    value: monitorGroup.modelData.brightness
                    valueLabel: monitorGroup.modelData.initialized ? Math.round(value * 100) + "%"
                        : monitorGroup.modelData.supported ? Tr.tr("Connecting…") : Tr.tr("Unavailable")
                    enabled: monitorGroup.modelData.supported && monitorGroup.modelData.initialized
                    stepSize: GlobalConfig.services.brightnessIncrement
                    onMoved: value => monitorGroup.modelData.setBrightness(value)
                }
            }
        }

        SectionHeader { text: Tr.tr("Side panel layouts") }

        Repeater {
            model: 3

            SelectRow {
                id: layoutRow

                required property int index
                readonly property int monitorCount: index + 1

                first: index === 0
                last: index === 2
                label: monitorCount === 1 ? Tr.tr("One monitor") : monitorCount === 2 ? Tr.tr("Two monitors") : Tr.tr("Three monitors")
                subtext: DisplaySettings.layoutFor(monitorCount) === "local"
                    ? Tr.tr("Volume, sunset, then this monitor's brightness") : Tr.tr("Volume beside all monitor brightness sliders")
                enabled: DisplaySettings.ready
                menuItems: [
                    MenuItem { text: Tr.tr("Per monitor"); property string layout: "local" },
                    MenuItem { text: Tr.tr("Combined"); property string layout: "combined" }
                ]
                active: menuItems.find(item => item.layout === DisplaySettings.layoutFor(monitorCount))
                onSelected: item => DisplaySettings.setLayout(monitorCount, item.layout)
            }
        }
    }
}
