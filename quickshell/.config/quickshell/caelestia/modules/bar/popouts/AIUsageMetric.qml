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

    required property var metric

    readonly property var elapsedPercent: {
        if (metric.windowSeconds > 0 && metric.resetAtMs !== null) {
            const remaining = Math.max(0, (metric.resetAtMs - AIUsage.clockNow) / 1000);
            return Math.max(0, Math.min(100, 100 * (metric.windowSeconds - remaining) / metric.windowSeconds));
        }
        return metric.elapsedPercent;
    }

    readonly property color accent: metric.severity === "critical" || metric.severity === "high" ? Colours.palette.m3error : metric.severity === "mid" ? Colours.palette.m3tertiary : Colours.palette.m3primary

    spacing: Tokens.spacing.extraSmall

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: root.metric.label
            font: Tokens.font.title.small
            elide: Text.ElideRight
        }

        StyledText {
            text: root.metric.percent === null ? root.metric.value : Tr.tr("%1% used").arg(Math.round(root.metric.percent))
            color: root.accent
        }
    }

    StyledProgressBar {
        Layout.fillWidth: true
        visible: root.metric.percent !== null
        from: 0
        to: 100
        value: root.metric.percent ?? 0
        fgColour: root.accent
        bgColour: Colours.palette.m3surfaceContainerHighest
        implicitHeight: 6
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.elapsedPercent !== null
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: Tr.tr("Window elapsed")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }

        StyledText {
            text: Tr.tr("%1% · %2").arg(Math.round(root.elapsedPercent)).arg(root.paceText)
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }
    }

    StyledProgressBar {
        Layout.fillWidth: true
        visible: root.elapsedPercent !== null
        from: 0
        to: 100
        value: root.elapsedPercent ?? 0
        fgColour: Colours.palette.m3secondary
        bgColour: Colours.palette.m3surfaceContainerHighest
        implicitHeight: 4
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.metric.resetAtMs !== null || root.metric.detail.length > 0
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            visible: root.metric.resetAtMs !== null
            text: Tr.tr("Resets in %1").arg(root.countdown)
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }

        StyledText {
            visible: root.metric.resetAtMs !== null
            text: Qt.formatDateTime(new Date(root.metric.resetAtMs), GlobalConfig.services.useTwelveHourClock ? "h:mm AP" : "HH:mm")
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
        }
    }

    StyledText {
        Layout.fillWidth: true
        visible: root.metric.detail.length > 0
        text: root.metric.detail
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.label.small
        wrapMode: Text.Wrap
    }

    readonly property string countdown: {
        if (root.metric.resetAtMs === null)
            return "";

        const remaining = Math.max(0, Math.floor((root.metric.resetAtMs - AIUsage.clockNow) / 1000));
        const days = Math.floor(remaining / 86400);
        const hours = Math.floor(remaining / 3600) % 24;
        const minutes = Math.floor(remaining / 60) % 60;
        const parts = [];
        if (days > 0)
            parts.push(Tr.trN("%n day", "%n days", days));
        if (hours > 0)
            parts.push(Tr.trN("%n hour", "%n hours", hours));
        if (minutes > 0 || parts.length === 0)
            parts.push(Tr.trN("%n min", "%n mins", minutes));
        return parts.join(" ");
    }

    readonly property string paceText: {
        if (root.metric.percent === null || root.elapsedPercent === null)
            return "";

        const difference = Math.round(root.metric.percent - root.elapsedPercent);
        if (Math.abs(difference) <= 3)
            return Tr.tr("On pace");
        return Tr.tr("%1% %2 pace").arg(Math.abs(difference)).arg(difference > 0 ? Tr.tr("over") : Tr.tr("under"));
    }
}
