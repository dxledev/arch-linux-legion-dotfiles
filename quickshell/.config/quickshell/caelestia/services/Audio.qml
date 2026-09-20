pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services

Singleton {
    id: root

    property string previousSinkName: ""
    property string previousSourceName: ""

    property list<PwNode> sinks: []
    property list<PwNode> sources: []
    property list<PwNode> streams: []
    property var outputOptions: []

    readonly property string hdmiCard: "alsa_card.pci-0000_01_00.1"
    readonly property string hdmiProfile: "output:hdmi-stereo-extra1"
    readonly property string hdmiSinkName: "alsa_output.pci-0000_01_00.1.hdmi-stereo-extra1"

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool muted: !!sink?.audio?.muted
    readonly property real volume: sink?.audio?.volume ?? 0

    readonly property bool sourceMuted: !!source?.audio?.muted
    readonly property real sourceVolume: source?.audio?.volume ?? 0

    readonly property alias cava: cava
    readonly property alias beatTracker: beatTracker

    function toggleMuted(): void {
        if (sink?.ready && sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    function setVolume(newVolume: real): void {
        if (sink?.ready && sink?.audio) {
            sink.audio.muted = false;
            sink.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementVolume(amount: real): void {
        setVolume(volume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementVolume(amount: real): void {
        setVolume(volume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setSourceVolume(newVolume: real): void {
        if (source?.ready && source?.audio) {
            source.audio.muted = false;
            source.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function incrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume + (amount || GlobalConfig.services.audioIncrement));
    }

    function decrementSourceVolume(amount: real): void {
        setSourceVolume(sourceVolume - (amount || GlobalConfig.services.audioIncrement));
    }

    function setAudioSink(newSink: PwNode): void {
        Pipewire.preferredDefaultAudioSink = newSink;
    }

    function sinkLabel(node: PwNode): string {
        if (node.name.includes("usb"))
            return "Headset";
        if (node.name.includes("analog"))
            return "Speakers";
        return "Audio";
    }

    function sinkIcon(node: PwNode): string {
        if (node.name.includes("usb"))
            return "󰋋";
        if (node.name.includes("analog"))
            return "󰓃";
        return "󰕾";
    }

    function isOutputSelected(output: var): bool {
        if (output.kind === "hdmi")
            return sink?.name === hdmiSinkName;
        return sink?.id === output.node?.id;
    }

    function selectOutput(output: var): void {
        if (output.kind === "hdmi") {
            switchHdmiOutput();
            return;
        }

        if (output.node)
            setAudioSink(output.node);
    }

    function switchHdmiOutput(): void {
        if (hdmiSwitch.running)
            return;

        hdmiSwitch.command = ["/usr/bin/bash", "-c", [
            "/usr/bin/pactl set-card-profile " + hdmiCard + " " + hdmiProfile,
            "found=0",
            "for _ in 1 2 3 4 5 6 7 8 9 10; do",
            "    if /usr/bin/pactl list sinks short | /usr/bin/awk -v target='" + hdmiSinkName + "' '$2 == target { found=1 } END { exit !found }'; then",
            "        found=1",
            "        break",
            "    fi",
            "    /usr/bin/sleep 0.2",
            "done",
            "if [ \"$found\" -ne 1 ]; then exit 1; fi",
            "/usr/bin/pactl set-default-sink " + hdmiSinkName,
            "/usr/bin/pactl list sink-inputs short | while read -r input rest; do /usr/bin/pactl move-sink-input \"$input\" " + hdmiSinkName + "; done"
        ].join("\n")];
        hdmiSwitch.running = true;
    }

    function setAudioSource(newSource: PwNode): void {
        Pipewire.preferredDefaultAudioSource = newSource;
    }

    function cycleNextAudioOutput(): void {
        if (sinks.length === 0)
            return;

        const currentIndex = sinks.findIndex(s => s === sink);
        const nextIndex = (currentIndex + 1) % sinks.length;
        setAudioSink(sinks[nextIndex]);
    }

    function setStreamVolume(stream: PwNode, newVolume: real): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = false;
            stream.audio.volume = Math.max(0, Math.min(GlobalConfig.services.maxVolume, newVolume));
        }
    }

    function setStreamMuted(stream: PwNode, muted: bool): void {
        if (stream?.ready && stream?.audio) {
            stream.audio.muted = muted;
        }
    }

    function getStreamVolume(stream: PwNode): real {
        return stream?.audio?.volume ?? 0;
    }

    function getStreamMuted(stream: PwNode): bool {
        return !!stream?.audio?.muted;
    }

    function getStreamName(stream: PwNode): string {
        if (!stream)
            return Tr.trCtx("Unknown", "unknown audio stream");
        // Try application name first, then description, then name
        return stream.properties["application.name"] || stream.description || stream.name || Tr.trCtx("Unknown application", "unknown application audio stream");
    }

    function refreshNodes(): void {
        const newSinks = [];
        const newSources = [];
        const newStreams = [];
        const newOutputOptions = [{
            kind: "hdmi",
            icon: "󰍹",
            label: "Acer"
        }];

        for (const node of Pipewire.nodes.values) {
            if (!node.isStream) {
                if (node.isSink) {
                    newSinks.push(node);
                    if (!node.name.includes("hdmi"))
                        newOutputOptions.push({ kind: "sink", node, icon: root.sinkIcon(node), label: root.sinkLabel(node) });
                } else if (node.audio) {
                    newSources.push(node);
                }
            } else if (node.audio) {
                newStreams.push(node);
            }
        }

        root.sinks = newSinks;
        root.sources = newSources;
        root.streams = newStreams;
        root.outputOptions = newOutputOptions;
    }

    onSinkChanged: {
        if (!sink?.ready)
            return;

        const newSinkName = sink.description || sink.name || Tr.trCtx("Unknown device", "unknown audio device");

        if (previousSinkName && previousSinkName !== newSinkName && GlobalConfig.utilities.toasts.audioOutputChanged)
            Toaster.toast(Tr.tr("Audio output changed"), Tr.tr("Now using: %1").arg(newSinkName), "volume_up");

        previousSinkName = newSinkName;
    }

    onSourceChanged: {
        if (!source?.ready)
            return;

        const newSourceName = source.description || source.name || Tr.trCtx("Unknown device", "unknown audio device");

        if (previousSourceName && previousSourceName !== newSourceName && GlobalConfig.utilities.toasts.audioInputChanged)
            Toaster.toast(Tr.tr("Audio input changed"), Tr.tr("Now using: %1").arg(newSourceName), "mic");

        previousSourceName = newSourceName;
    }

    // Populate immediately: Pipewire.nodes may already be filled by the time this
    // lazily-loaded singleton is created, so onValuesChanged would never fire.
    Component.onCompleted: {
        refreshNodes();
        previousSinkName = sink?.description || sink?.name || Tr.trCtx("Unknown device", "unknown audio device");
        previousSourceName = source?.description || source?.name || Tr.trCtx("Unknown device", "unknown audio device");
    }

    Connections {
        function onValuesChanged(): void {
            root.refreshNodes();
        }

        target: Pipewire.nodes
    }

    Process {
        id: hdmiSwitch

        onExited: exitCode => {
            if (exitCode !== 0)
                console.warn("Could not switch to Acer audio output");
        }
    }

    // Always track the current defaults so volume/mute bind even if the lists
    // momentarily lag behind the default node.
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources, ...root.streams].filter(n => n)
    }

    CavaProvider {
        id: cava

        bars: GlobalConfig.services.visualiserBars
    }

    BeatTracker {
        id: beatTracker
    }

    IpcHandler {
        function cycleOutput(): void {
            root.cycleNextAudioOutput();
        }

        target: "audio"
    }
}
