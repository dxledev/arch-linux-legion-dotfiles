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

    implicitWidth: layout.implicitWidth + Tokens.padding.large + layout.anchors.horizontalCenterOffset * 2
    implicitHeight: layout.implicitHeight + Tokens.padding.large * 2

    ColumnLayout {
        id: layout

        anchors.centerIn: parent
        anchors.horizontalCenterOffset: CUtils.clamp(Tokens.padding.large - Config.border.thickness, 0, Tokens.padding.large) / 2
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
            implicitHeight: Tokens.sizes.osd.sliderHeight

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

        Repeater {
            model: Config.osd.enableBrightness ? Brightness.osdMonitors : []

            delegate: BrightnessSlider {
                required property var modelData

                monitor: modelData.monitor
                label: modelData.label
                showInitialValue: root.initialValueDisplays[modelData.monitor.modelData.name] ?? false
            }
        }

        NightlightToggle {
            Layout.alignment: Qt.AlignHCenter
        }
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
