pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    required property PopoutState popouts

    implicitHeight: content.implicitHeight
    implicitWidth: 440
    width: implicitWidth

    Component.onCompleted: ProtonVpn.panelUsers++
    Component.onDestruction: ProtonVpn.panelUsers--

    ColumnLayout {
        id: content

        spacing: Tokens.spacing.medium
        width: root.width

        RowLayout {
            Layout.fillWidth: true

            MaterialIcon {
                color: Colours.palette.m3primary
                fill: ProtonVpn.connected ? 1 : 0
                fontStyle: Tokens.font.icon.large
                text: ProtonVpn.connected ? "vpn_key" : "vpn_key_off"
            }
            StyledText {
                Layout.fillWidth: true
                font: Tokens.font.title.medium
                text: Tr.tr("Proton VPN")
            }
            IconTextButton {
                disabled: ProtonVpn.refreshing || ProtonVpn.busy
                icon: "refresh"
                text: Tr.tr("Retry")
                type: IconTextButton.Tonal

                onClicked: {
                    ProtonVpn.actionError = "";
                    ProtonVpn.refresh();
                }
            }
        }
        StyledRect {
            Layout.fillWidth: true
            color: ProtonVpn.connected ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerLow
            implicitHeight: statusRow.implicitHeight + Tokens.padding.medium * 2
            radius: Tokens.rounding.large

            RowLayout {
                id: statusRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.fillWidth: true
                        color: ProtonVpn.connected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.title.medium
                        text: ProtonVpn.busy ? Tr.trMarked(ProtonVpn.pendingAction) : !ProtonVpn.linkKnown ? Tr.tr("Checking connection…") : ProtonVpn.connected ? Tr.tr("Protected") : Tr.tr("Not connected")
                    }
                    StyledText {
                        Layout.fillWidth: true
                        color: Colours.palette.m3onSurfaceVariant
                        text: ProtonVpn.connected ? [ProtonVpn.server, ProtonVpn.location].filter(value => value.length > 0).join(" · ") : !ProtonVpn.installed ? Tr.tr("Install proton-vpn-cli to get started") : ProtonVpn.accountKnown && !ProtonVpn.signedIn ? Tr.tr("Sign in to connect") : Tr.tr("Connect to protect your traffic")
                        textFormat: Text.PlainText
                        visible: text.length > 0
                        wrapMode: Text.Wrap
                    }
                }
                IconTextButton {
                    disabled: ProtonVpn.busy || !ProtonVpn.linkKnown
                    icon: "power_settings_new"
                    text: Tr.tr("Disconnect")
                    type: IconTextButton.Tonal
                    visible: ProtonVpn.connected

                    onClicked: ProtonVpn.disconnect()
                }
            }
        }
        StyledText {
            Layout.fillWidth: true
            color: Colours.palette.m3error
            text: [ProtonVpn.linkError, ProtonVpn.actionError || ProtonVpn.lastError].filter(value => value.length > 0).join("\n")
            textFormat: Text.PlainText
            visible: text.length > 0
            wrapMode: Text.Wrap
        }
        Repeater {
            model: ProtonVpn.details

            delegate: RowLayout {
                required property var modelData

                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    color: Colours.palette.m3onSurfaceVariant
                    text: modelData.label
                    textFormat: Text.PlainText
                }
                StyledText {
                    text: modelData.value
                    textFormat: Text.PlainText
                }
            }
        }
        ProtonVpnLocations {
            Layout.fillWidth: true
            popouts: root.popouts
            visible: ProtonVpn.signedIn
        }
        ProtonVpnProtections {
            Layout.fillWidth: true
            visible: ProtonVpn.signedIn
        }
        RowLayout {
            Layout.fillWidth: true
            visible: ProtonVpn.installed && ProtonVpn.accountKnown && !ProtonVpn.signedIn

            StyledTextField {
                id: username

                Layout.fillWidth: true
                placeholderText: Tr.tr("Proton username or email")
                validate: /^[A-Za-z0-9._+@-]{1,254}$/

                onAccepted: ProtonVpn.signIn(text)
                onActiveFocusChanged: {
                    if (activeFocus)
                        root.popouts.pinRequested();
                }
            }
            IconTextButton {
                disabled: username.text.trim().length === 0 || !username.valid || ProtonVpn.busy
                icon: "login"
                text: Tr.tr("Sign in")
                type: IconTextButton.Tonal

                onClicked: ProtonVpn.signIn(username.text)
            }
        }
    }
}
