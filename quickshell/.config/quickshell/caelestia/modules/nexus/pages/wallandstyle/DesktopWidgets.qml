pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    readonly property list<MenuItem> clockPositionItems: [
        MenuItem {
            text: Tr.tr("Top left")
            property string position: "top-left"
        },
        MenuItem {
            text: Tr.tr("Top center")
            property string position: "top-center"
        },
        MenuItem {
            text: Tr.tr("Top right")
            property string position: "top-right"
        },
        MenuItem {
            text: Tr.tr("Middle left")
            property string position: "middle-left"
        },
        MenuItem {
            text: Tr.tr("Middle center")
            property string position: "middle-center"
        },
        MenuItem {
            text: Tr.tr("Middle right")
            property string position: "middle-right"
        },
        MenuItem {
            text: Tr.tr("Bottom left")
            property string position: "bottom-left"
        },
        MenuItem {
            text: Tr.tr("Bottom center")
            property string position: "bottom-center"
        },
        MenuItem {
            text: Tr.tr("Bottom right")
            property string position: "bottom-right"
        }
    ]

    title: Tr.tr("Desktop widgets")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Desktop clock")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Enabled")
            checked: Config.background.desktopClock.enabled
            onToggled: GlobalConfig.background.desktopClock.enabled = checked
        }

        SelectRow {
            label: Tr.tr("Position")
            subtext: Tr.tr("Choose where the clock appears on each monitor")
            menuItems: root.clockPositionItems
            active: root.clockPositionItems.find(item => item.position === Config.background.desktopClock.position) ?? root.clockPositionItems[8]
            onSelected: item => GlobalConfig.background.desktopClock.position = item.position
        }

        SliderRow {
            icon: "zoom_in"
            label: Tr.tr("Scale")
            value: Config.background.desktopClock.scale
            from: 0.5
            to: 2.0
            valueLabel: `${Config.background.desktopClock.scale.toFixed(2)}x`
            onMoved: value => GlobalConfig.background.desktopClock.scale = value
        }

        ToggleRow {
            last: true
            text: Tr.tr("Invert colours")
            checked: Config.background.desktopClock.invertColors
            onToggled: GlobalConfig.background.desktopClock.invertColors = checked
        }

        SectionHeader {
            text: Tr.tr("Clock background")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Background")
            checked: Config.background.desktopClock.background.enabled
            onToggled: GlobalConfig.background.desktopClock.background.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Blur")
            disabled: !Config.background.desktopClock.background.enabled
            checked: Config.background.desktopClock.background.blur
            onToggled: GlobalConfig.background.desktopClock.background.blur = checked
        }

        SliderRow {
            last: true
            icon: "opacity"
            label: Tr.tr("Opacity")
            enabled: Config.background.desktopClock.background.enabled
            value: Config.background.desktopClock.background.opacity
            from: 0
            to: 1
            valueLabel: `${Math.round(Config.background.desktopClock.background.opacity * 100)}%`
            onMoved: value => GlobalConfig.background.desktopClock.background.opacity = value
        }

        SectionHeader {
            text: Tr.tr("Clock shadow")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Shadow")
            checked: Config.background.desktopClock.shadow.enabled
            onToggled: GlobalConfig.background.desktopClock.shadow.enabled = checked
        }

        SliderRow {
            icon: "blur_on"
            label: Tr.tr("Blur")
            enabled: Config.background.desktopClock.shadow.enabled
            value: Config.background.desktopClock.shadow.blur
            from: 0
            to: 1
            valueLabel: Config.background.desktopClock.shadow.blur.toFixed(2)
            onMoved: value => GlobalConfig.background.desktopClock.shadow.blur = value
        }

        SliderRow {
            last: true
            icon: "opacity"
            label: Tr.tr("Opacity")
            enabled: Config.background.desktopClock.shadow.enabled
            value: Config.background.desktopClock.shadow.opacity
            from: 0
            to: 1
            valueLabel: `${Math.round(Config.background.desktopClock.shadow.opacity * 100)}%`
            onMoved: value => GlobalConfig.background.desktopClock.shadow.opacity = value
        }

        SectionHeader {
            text: Tr.tr("Audio visualiser")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Enabled")
            checked: Config.background.visualiser.enabled
            onToggled: GlobalConfig.background.visualiser.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Auto-hide")
            subtext: Tr.tr("Hide the visualiser behind tiled windows")
            checked: Config.background.visualiser.autoHide
            onToggled: GlobalConfig.background.visualiser.autoHide = checked
        }

        ToggleRow {
            text: Tr.tr("Blur")
            checked: Config.background.visualiser.blur
            onToggled: GlobalConfig.background.visualiser.blur = checked
        }

        SliderRow {
            icon: "rounded_corner"
            label: Tr.tr("Rounding")
            value: Config.background.visualiser.rounding
            from: 0
            to: 2
            valueLabel: Config.background.visualiser.rounding.toFixed(1)
            onMoved: value => GlobalConfig.background.visualiser.rounding = value
        }

        SliderRow {
            last: true
            icon: "space_bar"
            label: Tr.tr("Spacing")
            value: Config.background.visualiser.spacing
            from: 0
            to: 3
            valueLabel: Config.background.visualiser.spacing.toFixed(1)
            onMoved: value => GlobalConfig.background.visualiser.spacing = value
        }
    }
}
