pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    required property ShellScreen screen
    required property ScreenState screenState
    required property bool sidebarOrSessionVisible
    required property bool audioPopoutVisible

    property bool hovered
    readonly property bool shouldBeActive: screenState.osd && Config.osd.enabled && !(screenState.utilities && Config.utilities.enabled)
    property real offsetScale: shouldBeActive ? 0 : 1
    property real sidebarOffset: sidebarOrSessionVisible ? 12 : 0

    property real volume
    property bool muted
    property real sourceVolume
    property bool sourceMuted
    property var pendingValueDisplays: ({})

    function show(control: string): void {
        if (screenState !== ShellState.forActive())
            return;
        if (!content.item) {
            const pending = Object.assign({}, pendingValueDisplays);
            pending[control] = true;
            pendingValueDisplays = pending;
        }
        screenState.osd = true;
        timer.restart();
    }

    function showAudio(control: string): void {
        if (!audioPopoutVisible)
            show(control);
    }

    Component.onCompleted: {
        volume = Audio.volume;
        muted = Audio.muted;
        sourceVolume = Audio.sourceVolume;
        sourceMuted = Audio.sourceMuted;
    }

    visible: offsetScale < 1
    anchors.rightMargin: (-implicitWidth - 5 - sidebarOffset) * offsetScale
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    opacity: 1 - offsetScale

    Behavior on offsetScale {
        Anim {}
    }

    Connections {
        function onMutedChanged(): void {
            root.showAudio("volume");
            root.muted = Audio.muted;
        }

        function onVolumeChanged(): void {
            root.showAudio("volume");
            root.volume = Audio.volume;
        }

        function onSourceMutedChanged(): void {
            root.showAudio("microphone");
            root.sourceMuted = Audio.sourceMuted;
        }

        function onSourceVolumeChanged(): void {
            root.showAudio("microphone");
            root.sourceVolume = Audio.sourceVolume;
        }

        target: Audio
    }

    Instantiator {
        model: Brightness.osdMonitors

        delegate: Connections {
            required property var modelData

            target: modelData.monitor
            function onBrightnessChanged(): void {
                if (modelData.monitor.initialized)
                    root.show(modelData.monitor.modelData.name);
            }
        }
    }

    Timer {
        id: timer

        interval: root.Config.osd.hideDelay
        onTriggered: {
            if (!root.hovered)
                root.screenState.osd = false;
        }
    }

    Loader {
        id: content

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left

        asynchronous: true
        active: root.shouldBeActive || root.visible
        onActiveChanged: {
            if (!active)
                root.pendingValueDisplays = {};
        }

        sourceComponent: Content {
            initialValueDisplays: root.pendingValueDisplays
            screenState: root.screenState
            volume: root.volume
            muted: root.muted
            sourceVolume: root.sourceVolume
            sourceMuted: root.sourceMuted
        }
    }
}
