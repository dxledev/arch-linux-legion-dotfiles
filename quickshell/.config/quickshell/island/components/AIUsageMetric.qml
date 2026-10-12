import QtQuick
import QtQuick.Layouts
import "../styles"

ColumnLayout {
    id: root

    objectName: "ai-usage-metric"
    required property var metric
    property double clockNow: Date.now()
    property bool clock12Hour: false

    function finiteNumber(value) {
        return typeof value === "number" && Number.isFinite(value);
    }

    readonly property bool hasPercent: finiteNumber(metric.percent)
    readonly property real usagePercent: hasPercent ? Math.max(0, Math.min(100, metric.percent)) : 0
    readonly property bool hasReset: finiteNumber(metric.resetAtMs)
    readonly property var elapsedPercent: {
        const windowSeconds = metric.windowSeconds;
        if (hasReset && finiteNumber(windowSeconds) && windowSeconds > 0) {
            const remaining = Math.max(0, (metric.resetAtMs - clockNow) / 1000);
            return Math.max(0, Math.min(100, 100 * (windowSeconds - remaining) / windowSeconds));
        }
        const elapsed = metric.elapsedPercent;
        return finiteNumber(elapsed) ? Math.max(0, Math.min(100, elapsed)) : null;
    }
    readonly property color usageColor: ["critical", "high"].includes(String(metric.severity).toLowerCase()) ? Theme.danger : String(metric.severity).toLowerCase() === "mid" ? Theme.warning : Theme.accent
    readonly property string paceText: {
        if (!hasPercent || elapsedPercent === null)
            return "";
        const difference = Math.round(usagePercent - elapsedPercent);
        if (Math.abs(difference) <= 3)
            return "On pace";
        return Math.abs(difference) + "% " + (difference > 0 ? "over" : "under") + " pace";
    }
    readonly property string countdown: {
        if (!hasReset)
            return "";
        const remaining = Math.max(0, Math.floor((metric.resetAtMs - clockNow) / 1000));
        const days = Math.floor(remaining / 86400);
        const hours = Math.floor(remaining / 3600) % 24;
        const minutes = Math.floor(remaining / 60) % 60;
        const parts = [];
        if (days > 0)
            parts.push(days + "d");
        if (hours > 0)
            parts.push(hours + "h");
        if (minutes > 0 || parts.length === 0)
            parts.push(minutes + "m");
        return parts.join(" ");
    }

    spacing: 7

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        UiText {
            Layout.fillWidth: true
            text: root.metric.label ?? ""
            textFormat: Text.PlainText
            color: Theme.textPrimary
            font.pixelSize: 14
            elide: Text.ElideRight
        }

        UiText {
            text: root.hasPercent ? Math.round(root.usagePercent) + "% used" : root.metric.value ?? ""
            textFormat: Text.PlainText
            color: root.usageColor
            font.pixelSize: 12
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 7
        visible: root.hasPercent
        radius: height / 2
        color: Theme.surfaceVariant

        Rectangle {
            width: parent.width * root.usagePercent / 100
            height: parent.height
            radius: parent.radius
            color: root.usageColor
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.elapsedPercent !== null
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            UiText {
                Layout.fillWidth: true
                text: "Window elapsed"
                color: Theme.textSecondary
                font.pixelSize: 11
            }

            UiText {
                text: Math.round(root.elapsedPercent) + "% · " + root.paceText
                color: Theme.textSecondary
                font.pixelSize: 11
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 4
            radius: height / 2
            color: Theme.surfaceVariant

            Rectangle {
                width: parent.width * root.elapsedPercent / 100
                height: parent.height
                radius: parent.radius
                color: Theme.textSecondary
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: root.hasReset
        spacing: 8

        UiText {
            Layout.fillWidth: true
            text: "Resets in " + root.countdown
            color: Theme.textSecondary
            font.pixelSize: 11
        }

        UiText {
            text: Qt.formatDateTime(new Date(root.metric.resetAtMs), root.clock12Hour ? "MMM d, h:mm AP" : "MMM d, HH:mm")
            color: Theme.textSecondary
            font.pixelSize: 11
        }
    }

    UiText {
        Layout.fillWidth: true
        visible: !root.hasReset && String(root.metric.detail ?? "").length > 0
        text: root.metric.detail ?? ""
        textFormat: Text.PlainText
        color: Theme.textSecondary
        font.pixelSize: 11
        wrapMode: Text.Wrap
    }
}
