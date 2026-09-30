pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    spacing: Tokens.spacing.small

    RowLayout {
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Tr.tr("Kill Switch")
            }
            StyledText {
                Layout.fillWidth: true
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
                text: Tr.tr("Block traffic if the VPN connection drops")
                wrapMode: Text.Wrap
            }
        }
        StyledSwitch {
            checked: ProtonVpn.configuration["kill-switch"] === "standard"
            disabled: ProtonVpn.busy || !["off", "standard"].includes(ProtonVpn.configuration["kill-switch"])

            onClicked: ProtonVpn.setConfig("kill-switch", checked ? "standard" : "off")
        }
    }
    StyledText {
        text: Tr.tr("NetShield")
    }
    RowLayout {
        Layout.fillWidth: true

        Repeater {
            model: [
                {
                    label: Tr.tr("Off"),
                    value: "off"
                },
                {
                    label: Tr.tr("Malware"),
                    value: "malware-only"
                },
                {
                    label: Tr.tr("Ads + trackers"),
                    value: "malware-ads-trackers"
                }
            ]

            delegate: TextButton {
                required property var modelData

                Layout.fillWidth: true
                checked: ProtonVpn.configuration.netshield === modelData.value
                disabled: ProtonVpn.busy || !["off", "malware-only", "malware-ads-trackers"].includes(ProtonVpn.configuration.netshield)
                isToggle: true
                text: modelData.label
                type: TextButton.Tonal

                onClicked: ProtonVpn.setConfig("netshield", modelData.value)
            }
        }
    }
    StyledText {
        Layout.fillWidth: true
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.small
        text: ProtonVpn.configuration.netshield || ""
        textFormat: Text.PlainText
        visible: !!ProtonVpn.configuration.netshield && !["off", "malware-only", "malware-ads-trackers"].includes(ProtonVpn.configuration.netshield)
        wrapMode: Text.Wrap
    }
}
