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

    required property PopoutState popouts

    function formatElapsed(seconds: real): string {
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        const remainingSeconds = Math.floor(seconds % 60).toString().padStart(2, "0");

        if (hours > 0)
            return `${hours}:${minutes.toString().padStart(2, "0")}:${remainingSeconds}`;
        return `${minutes}:${remainingSeconds}`;
    }

    spacing: Tokens.spacing.medium
    implicitWidth: Tokens.sizes.bar.trayMenuWidth

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.medium

        MaterialIcon {
            Layout.alignment: Qt.AlignVCenter
            animate: true
            text: Recorder.paused ? "pause_circle" : "screen_record"
            color: Recorder.paused ? Colours.palette.m3tertiary : Colours.palette.m3error
            fontStyle: Tokens.font.icon.large
            fill: 1
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Screen recording")
                font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: Recorder.paused ? Tr.tr("Paused at %1").arg(root.formatElapsed(Recorder.elapsed)) : Tr.tr("Recording for %1").arg(root.formatElapsed(Recorder.elapsed))
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        IconTextButton {
            Layout.fillWidth: true
            icon: Recorder.paused ? "play_arrow" : "pause"
            text: Recorder.paused ? Tr.tr("Resume") : Tr.tr("Pause")
            type: IconTextButton.Tonal
            onClicked: Recorder.togglePause()
        }

        IconTextButton {
            Layout.fillWidth: true
            icon: "stop"
            text: Tr.tr("Stop")
            inactiveColour: Colours.palette.m3error
            inactiveOnColour: Colours.palette.m3onError
            onClicked: {
                Recorder.stop();
                root.popouts.hasCurrent = false;
            }
        }
    }
}
