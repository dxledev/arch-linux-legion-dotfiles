pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var outputs: Pipewire.nodes.values.filter(node => !node.isStream && node.isSink && node.audio)
    readonly property var inputs: Pipewire.nodes.values.filter(node => !node.isStream && !node.isSink && node.audio)
    readonly property string outputLabel: sink?.description || sink?.name || "No audio output"
    readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)
    readonly property bool muted: !!sink?.audio?.muted

    readonly property url volumeIcon: {
        if (muted)
            return "../assets/icons/volume-off.svg"
        if (volume <= 5)
            return "../assets/icons/volume-0.svg"
        if (volume <= 40)
            return "../assets/icons/volume-1.svg"
        return "../assets/icons/volume-2.svg"
    }

    PwObjectTracker {
        objects: [root.sink, root.source].concat(root.outputs, root.inputs).filter(node => node)
    }

    function setVolume(value) {
        if (sink?.ready && sink.audio && Number.isFinite(value))
            sink.audio.volume = Math.max(0, Math.min(100, value)) / 100
    }

    function toggleMute() {
        if (sink?.ready && sink.audio)
            sink.audio.muted = !sink.audio.muted
    }

    function selectOutput(node) {
        if (outputs.includes(node))
            Pipewire.preferredDefaultAudioSink = node
    }

    function selectInput(node) {
        if (inputs.includes(node))
            Pipewire.preferredDefaultAudioSource = node
    }
}
