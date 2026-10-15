pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import "../core"
import "../services"
import "../styles"

FocusScope {
    id: root
    implicitWidth: 520
    implicitHeight: content.implicitHeight + 44
    focus: true

    readonly property bool connected: ProtonVpnService.connected
    readonly property bool busy: ProtonVpnService.busy
    readonly property bool signedIn: ProtonVpnService.signedIn
    readonly property bool needsSignIn: ProtonVpnService.installed && ProtonVpnService.accountKnown && !ProtonVpnService.signedIn
    readonly property bool killSwitchOn: (ProtonVpnService.configuration["kill-switch"] ?? "off").toLowerCase() !== "off"
    readonly property string query: countryFilter.text.trim().toLowerCase()
    readonly property var visibleCountries: ProtonVpnService.countries.filter(country =>
        query.length === 0 || country.name.toLowerCase().indexOf(query) !== -1 || country.code.toLowerCase() === query)

    property real spinAngle: 0

    NumberAnimation {
        target: root
        property: "spinAngle"
        running: root.busy
        loops: Animation.Infinite
        from: 0
        to: 360
        duration: 900
    }

    Component.onCompleted: ProtonVpnService.acquirePanel()
    Component.onDestruction: ProtonVpnService.releasePanel()

    Keys.onEscapePressed: IslandController.openNavigation()

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        PanelHeader {
            Layout.fillWidth: true
            title: "Proton VPN"
            scrollTargets: [countryList]
            onBack: IslandController.openNavigation()
        }

        Rectangle {
            objectName: "protonvpn-status-card"
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            radius: 22
            color: root.connected ? Theme.surfaceVariant : Theme.surface
            Behavior on color { ColorAnimation { duration: Theme.animationFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 12
                spacing: 12

                SvgIcon {
                    source: root.busy ? "../assets/icons/refresh.svg"
                        : root.connected ? "../assets/icons/shield-lock.svg" : "../assets/icons/shield-off.svg"
                    size: 22
                    color: root.connected ? Theme.accent : Theme.textSecondary
                    rotation: root.busy ? root.spinAngle : 0
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    UiText {
                        objectName: "protonvpn-status-title"
                        Layout.fillWidth: true
                        text: ProtonVpnService.title
                        color: Theme.textPrimary
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    UiText {
                        objectName: "protonvpn-status-subtitle"
                        Layout.fillWidth: true
                        text: ProtonVpnService.subtitle
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                TextActionButton {
                    objectName: "protonvpn-disconnect-button"
                    visible: root.connected
                    enabled: !root.busy && ProtonVpnService.linkKnown
                    text: "Disconnect"
                    onClicked: ProtonVpnService.disconnect()
                }

                TextActionButton {
                    objectName: "protonvpn-connect-button"
                    visible: !root.connected && root.signedIn
                    enabled: !root.busy && ProtonVpnService.linkKnown
                    text: "Connect"
                    onClicked: ProtonVpnService.connect("", false)
                }

                IconButton {
                    objectName: "protonvpn-refresh-button"
                    iconSource: "../assets/icons/refresh.svg"
                    description: "Check again"
                    enabled: !root.busy && !ProtonVpnService.refreshing
                    opacity: enabled ? 1 : 0.5
                    onClicked: {
                        ProtonVpnService.actionError = "";
                        ProtonVpnService.refresh();
                    }
                }
            }
        }

        UiText {
            objectName: "protonvpn-error"
            Layout.fillWidth: true
            visible: text.length > 0
            text: ProtonVpnService.error
            color: Theme.danger
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        Repeater {
            model: root.connected ? ProtonVpnService.details : []

            delegate: RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6

                UiText {
                    Layout.fillWidth: true
                    text: modelData.label
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }

                UiText {
                    text: modelData.value
                    color: Theme.textPrimary
                    font.pixelSize: 12
                }
            }
        }

        RowLayout {
            objectName: "protonvpn-signin-row"
            Layout.fillWidth: true
            visible: root.needsSignIn
            spacing: 10

            SearchField {
                id: username
                Layout.fillWidth: true
                placeholderText: "Proton username or email"
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhEmailCharactersOnly
                onAccepted: ProtonVpnService.signIn(text)
            }

            TextActionButton {
                objectName: "protonvpn-signin-button"
                enabled: username.text.trim().length > 0 && !root.busy
                text: "Sign in"
                onClicked: ProtonVpnService.signIn(username.text)
            }
        }

        UiText {
            Layout.fillWidth: true
            Layout.leftMargin: 6
            visible: root.needsSignIn
            text: "Password and two-factor prompts open in your terminal."
            color: Theme.textMuted
            font.pixelSize: 11
            wrapMode: Text.WordWrap
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.signedIn
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                SearchField {
                    id: countryFilter
                    objectName: "protonvpn-country-filter"
                    Layout.fillWidth: true
                    placeholderText: "Search countries"
                    onNavigateDown: countryList.forceActiveFocus()
                }

                TextActionButton {
                    objectName: "protonvpn-random-button"
                    enabled: !root.busy
                    text: "Random"
                    onClicked: ProtonVpnService.connect("", true)
                }
            }

            ListView {
                id: countryList
                objectName: "protonvpn-country-list"
                readonly property bool scrollAnimationRunning: wheelScroll.animating
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(220, Math.max(54, contentHeight))
                model: root.visibleCountries
                spacing: 6
                clip: true
                SmoothScroll { id: wheelScroll; scrollTarget: countryList }
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar {}

                delegate: Button {
                    id: row
                    required property var modelData
                    x: 1
                    width: countryList.width - 2
                    height: 44
                    padding: 12
                    enabled: !root.busy
                    hoverEnabled: true
                    focusPolicy: Qt.TabFocus
                    Accessible.name: "Connect to " + modelData.name
                    onClicked: ProtonVpnService.connect(modelData.code, false)

                    HoverHandler { cursorShape: Qt.PointingHandCursor }

                    contentItem: RowLayout {
                        spacing: 12

                        UiText {
                            Layout.fillWidth: true
                            text: row.modelData.name
                            color: Theme.textPrimary
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        UiText {
                            text: row.modelData.code
                            color: Theme.textMuted
                            font.pixelSize: 11
                        }
                    }

                    background: Rectangle {
                        radius: 16
                        color: row.down ? Theme.buttonPressed : row.hovered ? Theme.surfaceVariant : Theme.surface
                        border.width: row.activeFocus ? 2 : 0
                        border.color: Theme.accent
                        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                    }
                }

                UiText {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: countryList.count === 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: ProtonVpnService.countries.length === 0 ? "Loading countries…" : "No country matches your search"
                    color: Theme.textSecondary
                    font.pixelSize: 13
                }
            }

            Switch {
                id: killSwitch
                objectName: "protonvpn-kill-switch"
                Layout.fillWidth: true
                implicitHeight: 40
                padding: 0
                enabled: !root.busy
                checked: root.killSwitchOn
                Accessible.name: "Kill switch"
                onToggled: ProtonVpnService.setConfig("kill-switch", checked ? "standard" : "off")

                contentItem: ColumnLayout {
                    spacing: 0

                    UiText {
                        Layout.fillWidth: true
                        Layout.rightMargin: 64
                        text: "Kill switch"
                        color: Theme.textPrimary
                        font.pixelSize: 14
                    }

                    UiText {
                        Layout.fillWidth: true
                        Layout.rightMargin: 64
                        text: "Block traffic if the VPN drops"
                        color: Theme.textSecondary
                        font.pixelSize: 11
                    }
                }

                indicator: Rectangle {
                    x: killSwitch.width - width
                    y: (killSwitch.height - height) / 2
                    width: 50
                    height: 30
                    radius: 15
                    color: killSwitch.checked ? Theme.accent : Theme.surfaceVariant
                    Behavior on color { ColorAnimation { duration: Theme.animationFast } }

                    Rectangle {
                        x: killSwitch.checked ? parent.width - width - 3 : 3
                        y: 3
                        width: 24
                        height: 24
                        radius: 12
                        color: Theme.textPrimary
                        Behavior on x { NumberAnimation { duration: Theme.animationFast; easing.type: Easing.OutCubic } }
                    }
                }
            }
        }
    }
}
