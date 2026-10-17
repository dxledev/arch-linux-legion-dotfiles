pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../components"
import "../core"
import "../services"
import "../styles"

FocusScope {
    id: root
    implicitWidth: 520
    implicitHeight: content.implicitHeight + 44
    focus: true

    readonly property var device: UPower.displayDevice
    readonly property bool hasBattery: device.isLaptopBattery
    readonly property int percentage: Math.round(device.percentage * 100)
    readonly property int profile: PowerProfiles.profile

    // Every profile the machine offers, in the order the selector shows them.
    readonly property var profiles: {
        const list = [{
            value: PowerProfile.PowerSaver,
            title: "Power saver",
            icon: "../assets/icons/leaf.svg",
            detail: "Quieter and cooler, with the longest battery life."
        }, {
            value: PowerProfile.Balanced,
            title: "Balanced",
            icon: "../assets/icons/scale.svg",
            detail: "Everyday speed without wasting power."
        }];
        if (PowerProfiles.hasPerformanceProfile) {
            list.push({
                value: PowerProfile.Performance,
                title: "Performance",
                icon: "../assets/icons/rocket.svg",
                detail: "Full speed for heavy work, with more heat and fan noise."
            });
        }
        return list;
    }
    readonly property int currentIndex: {
        for (let index = 0; index < profiles.length; index++) {
            if (profiles[index].value === profile) return index;
        }
        return 1;
    }

    function formatSeconds(seconds) {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor(seconds / 60) % 60;
        if (hours > 0) return hours + " h " + minutes + " min";
        return Math.max(1, minutes) + " min";
    }

    function batteryTitle() {
        if (!hasBattery) return "No battery detected";
        return percentage + "%" + (UPower.onBattery ? " · On battery" : device.state === UPowerDeviceState.FullyCharged ? " · Full" : " · Charging");
    }

    function batteryDetail() {
        if (!hasBattery) return "Power profile: " + (profiles[currentIndex]?.title ?? "Unknown");
        if (UPower.onBattery)
            return device.timeToEmpty > 0 ? formatSeconds(device.timeToEmpty) + " remaining" : "Estimating time remaining…";
        if (device.timeToFull > 0) return formatSeconds(device.timeToFull) + " until charged";
        return percentage >= 100 ? "Fully charged" : "Estimating time until charged…";
    }

    function degradationText() {
        switch (PowerProfiles.degradationReason) {
        case PerformanceDegradationReason.HighTemperature: return "The device is too hot, so performance is limited.";
        case PerformanceDegradationReason.LapDetected: return "The device is on a lap, so performance is limited.";
        default: return "Performance is limited for an unknown reason.";
        }
    }

    function select(index) {
        const entry = profiles[index];
        if (entry) PowerProfiles.profile = entry.value;
    }

    Keys.onEscapePressed: IslandController.reset()
    Keys.onLeftPressed: select(Math.max(0, currentIndex - 1))
    Keys.onRightPressed: select(Math.min(profiles.length - 1, currentIndex + 1))

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 22
        spacing: 18

        PanelHeader {
            Layout.fillWidth: true
            title: "Power profile"
            onBack: IslandController.openNavigation()
        }

        Rectangle {
            objectName: "power-profile-battery-card"
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            radius: 22
            color: Theme.surface

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                SvgIcon {
                    source: "../assets/icons/battery-charging.svg"
                    size: 22
                    color: root.hasBattery && !UPower.onBattery ? Theme.accent : Theme.textSecondary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    UiText {
                        objectName: "power-profile-battery-title"
                        Layout.fillWidth: true
                        text: root.batteryTitle()
                        color: Theme.textPrimary
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    UiText {
                        Layout.fillWidth: true
                        text: root.batteryDetail()
                        color: Theme.textSecondary
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Rectangle {
            id: selector
            objectName: "power-profile-selector"
            Layout.fillWidth: true
            Layout.preferredHeight: 76
            radius: 22
            color: Theme.surface

            readonly property real inset: 6
            readonly property real segmentWidth: (width - inset * 2) / Math.max(1, root.profiles.length)

            // One pill slides to the chosen profile instead of each segment recoloring on its own.
            Rectangle {
                objectName: "power-profile-indicator"
                x: selector.inset + root.currentIndex * selector.segmentWidth
                y: selector.inset
                width: selector.segmentWidth
                height: selector.height - selector.inset * 2
                radius: selector.radius - selector.inset
                color: Theme.accent

                Behavior on x {
                    NumberAnimation { duration: Theme.animationNormal; easing.type: Easing.OutCubic }
                }
            }

            Repeater {
                model: root.profiles

                delegate: Button {
                    id: segment
                    required property var modelData
                    required property int index
                    readonly property bool current: index === root.currentIndex

                    objectName: "power-profile-" + modelData.title.toLowerCase().replace(" ", "-")
                    x: selector.inset + index * selector.segmentWidth
                    y: selector.inset
                    width: selector.segmentWidth
                    height: selector.height - selector.inset * 2
                    padding: 0
                    hoverEnabled: true
                    focusPolicy: Qt.TabFocus
                    Accessible.name: modelData.title
                    Accessible.checkable: true
                    Accessible.checked: current
                    onClicked: root.select(index)

                    HoverHandler { cursorShape: Qt.PointingHandCursor }

                    background: Rectangle {
                        radius: selector.radius - selector.inset
                        color: segment.hovered && !segment.current ? Theme.surfaceVariant : "transparent"
                        border.width: segment.activeFocus ? 2 : 0
                        border.color: segment.current ? Theme.background : Theme.accent
                        Behavior on color { ColorAnimation { duration: Theme.animationFast } }
                    }

                    // A Button puts its content at the top; centre the icon and label as one block.
                    contentItem: Item {
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            spacing: 6

                            Item {
                                width: parent.width
                                height: 20

                                SvgIcon {
                                    anchors.centerIn: parent
                                    source: segment.modelData.icon
                                    size: 20
                                    color: segment.current ? Theme.background : Theme.textPrimary
                                }
                            }

                            UiText {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: segment.modelData.title
                                font.pixelSize: 12
                                font.bold: true
                                color: segment.current ? Theme.background : Theme.textPrimary
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        UiText {
            objectName: "power-profile-detail"
            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            text: root.profiles[root.currentIndex]?.detail ?? ""
            color: Theme.textSecondary
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }

        Rectangle {
            objectName: "power-profile-degraded"
            Layout.fillWidth: true
            visible: PowerProfiles.degradationReason !== PerformanceDegradationReason.None
            implicitHeight: degradedRow.implicitHeight + 28
            radius: 16
            color: Theme.surface
            border.width: 1
            border.color: Theme.danger

            RowLayout {
                id: degradedRow
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                SvgIcon {
                    source: "../assets/icons/gauge.svg"
                    size: 18
                    color: Theme.danger
                }

                UiText {
                    Layout.fillWidth: true
                    text: root.degradationText()
                    color: Theme.textPrimary
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
