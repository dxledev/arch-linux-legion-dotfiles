pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    property bool expanded: false
    readonly property var matches: ProtonVpn.countries.filter(country => (country.name + " " + country.code).toLowerCase().includes(search.text.trim().toLowerCase()))
    required property PopoutState popouts

    spacing: Tokens.spacing.small

    RowLayout {
        Layout.fillWidth: true

        IconTextButton {
            Layout.fillWidth: true
            disabled: !ProtonVpn.signedIn || ProtonVpn.busy
            icon: "bolt"
            text: Tr.tr("Fastest")
            type: IconTextButton.Tonal

            onClicked: ProtonVpn.connect("", false)
        }
        IconTextButton {
            Layout.fillWidth: true
            disabled: !ProtonVpn.signedIn || ProtonVpn.busy
            icon: "shuffle"
            text: Tr.tr("Random")
            type: IconTextButton.Tonal

            onClicked: ProtonVpn.connect("", true)
        }
        IconButton {
            disabled: !ProtonVpn.signedIn || ProtonVpn.busy
            icon: root.expanded ? "expand_less" : "public"
            type: IconButton.Tonal

            onClicked: root.expanded = !root.expanded
        }
    }
    StyledTextField {
        id: search

        Layout.fillWidth: true
        leadingIcon: "search"
        placeholderText: Tr.tr("Search countries")
        visible: root.expanded

        onActiveFocusChanged: {
            if (activeFocus)
                root.popouts.pinRequested();
        }
    }
    ListView {
        id: countryList

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 176)
        clip: true
        model: root.matches
        spacing: Tokens.spacing.extraSmall
        visible: root.expanded

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: countryList
        }
        delegate: StyledRect {
            id: countryItem

            required property var modelData

            color: Colours.palette.m3surfaceContainerLow
            height: countryLabel.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.medium
            width: countryList.width

            StateLayer {
                disabled: ProtonVpn.busy
                radius: countryItem.radius

                onClicked: ProtonVpn.connect(countryItem.modelData.code, false)
            }
            StyledText {
                id: countryLabel

                anchors.fill: parent
                anchors.margins: Tokens.padding.small
                elide: Text.ElideRight
                text: countryItem.modelData.name + " · " + countryItem.modelData.code
                textFormat: Text.PlainText
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
    StyledText {
        Layout.fillWidth: true
        color: Colours.palette.m3onSurfaceVariant
        text: ProtonVpn.refreshing ? Tr.tr("Loading countries…") : Tr.tr("No countries available. Retry to refresh.")
        visible: root.expanded && root.matches.length === 0
        wrapMode: Text.Wrap
    }
}
