pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.utils

Item {
    id: root

    required property ScreenState screenState
    required property var initialValueDisplays

    required property real volume
    required property bool muted
    required property real sourceVolume
    required property bool sourceMuted

    readonly property int brightnessSliderCount: Config.osd.enableBrightness ? Brightness.osdMonitors.length : 0
    readonly property real brightnessStackHeight: brightnessSliderCount * Tokens.sizes.osd.sliderHeight
        + nightlightToggle.implicitHeight + brightnessSliderCount * brightnessColumn.spacing

    implicitWidth: layout.implicitWidth + Tokens.padding.large + layout.anchors.horizontalCenterOffset * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    RowLayout {
        id: layout

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: CUtils.clamp(Tokens.padding.large - Config.border.thickness, 0, Tokens.padding.large) / 2
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.spacing.medium

            // Speaker volume
            CustomMouseArea {
                function onWheel(event: WheelEvent) {
                    if (event.angleDelta.y > 0)
                        Audio.incrementVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementVolume();
                }

                implicitWidth: Tokens.sizes.osd.sliderWidth
                implicitHeight: Math.max(Tokens.sizes.osd.sliderHeight, root.brightnessStackHeight - nightlightToggle.implicitHeight)
                Layout.preferredHeight: implicitHeight

                FilledSlider {
                    id: volumeSlider

                    anchors.fill: parent
                    hoverEnabled: true

                    icon: Icons.getVolumeIcon(value, root.muted)
                    value: root.volume
                    showInitialValue: root.initialValueDisplays.volume ?? false
                    to: GlobalConfig.services.maxVolume
                    onMoved: Audio.setVolume(value)

                    onRightClicked: Audio.toggleMuted()

                    OsdTooltip {
                        parent: volumeSlider
                        Tokens.screen: root.Tokens.screen
                        visible: volumeSlider.hovered || volumeSlider.pressed
                        text: root.muted ? "Volume (Muted)" : "Volume"
                    }
                }
            }

            // Microphone volume
            WrappedLoader {
                shouldBeActive: Config.osd.enableMicrophone && (!Config.osd.enableBrightness || !root.screenState.session)

                sourceComponent: CustomMouseArea {
                    function onWheel(event: WheelEvent) {
                        if (event.angleDelta.y > 0)
                            Audio.incrementSourceVolume();
                        else if (event.angleDelta.y < 0)
                            Audio.decrementSourceVolume();
                    }

                    implicitWidth: Tokens.sizes.osd.sliderWidth
                    implicitHeight: Tokens.sizes.osd.sliderHeight

                    FilledSlider {
                        anchors.fill: parent

                        icon: Icons.getMicVolumeIcon(value, root.sourceMuted)
                        value: root.sourceVolume
                        showInitialValue: root.initialValueDisplays.microphone ?? false
                        to: GlobalConfig.services.maxVolume
                        onMoved: Audio.setSourceVolume(value)
                    }
                }
            }
        }

        ColumnLayout {
            id: brightnessColumn

            spacing: Tokens.spacing.medium

            Repeater {
                model: Config.osd.enableBrightness ? Brightness.osdMonitors.slice(0, 1) : []
                delegate: MonitorBrightnessSlider {}
            }

            NightlightToggle {
                id: nightlightToggle

                Layout.alignment: Qt.AlignHCenter
            }

            Repeater {
                model: Config.osd.enableBrightness ? Brightness.osdMonitors.slice(1) : []
                delegate: MonitorBrightnessSlider {}
            }
        }
    }

    component MonitorBrightnessSlider: BrightnessSlider {
        required property var modelData

        monitor: modelData.monitor
        label: modelData.label
        showInitialValue: root.initialValueDisplays[modelData.monitor.modelData.name] ?? false
    }

    component WrappedLoader: Loader {
        required property bool shouldBeActive

        asynchronous: true
        Layout.preferredHeight: shouldBeActive ? Tokens.sizes.osd.sliderHeight : 0
        opacity: shouldBeActive ? 1 : 0
        active: opacity > 0
        visible: active

        Behavior on Layout.preferredHeight {
            Anim {
                type: Anim.Emphasized
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }
}
